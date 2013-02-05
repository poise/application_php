def load_current_resource
  new_resource.composer_command node[:php][:composer][:exec] unless new_resource.composer_command
  default_params = Mash.new(
    :database_driver => 'pdo_mysql',
    :database_host => 'localhost',
    :database_port => '~',
    :database_name => 'symfony',
    :database_user => 'root',
    :database_password => '~',
    :mailer_transport => 'smtp',
    :mailer_host => 'localhost',
    :mailer_user => '~',
    :mailer_password => '~',
    :locale => 'en',
    :secret => 'CHANGEME'
  )
  new_resource.parameters Chef::Mixin::DeepMerge.merge(default_params, new_resource.parameters)
  new_resource.purge_before_symlink.replace %w(app/cache app/logs app/sessions tmp)
  new_resource.create_dirs_before_symlink.replace %w(cache logs sessions tmp)
  new_resource.symlinks.update(
    'cache' => 'app/cache',
    'logs' => 'app/logs',
    'sessions' => 'app/sessions',
    'tmp' => 'tmp'
  )
end

action :before_compile do
  new_resource.symlink_before_migrate.update(
    'parameters.yml' => 'app/config/parameters.yml'
  )
end

action :before_deploy do
  create_parameters_yml
end

action :before_migrate do

  link "#{new_resource.release_path}/app/config/parameters.yml" do
    to "#{new_resource.path}/shared/parameters.yml"
  end

  if new_resource.composer
    Chef::Log.info "Running composer install"
    directory "#{new_resource.path}/shared/vendor" do
      owner new_resource.owner
      group new_resource.group
      mode '0755'
    end

    directory "#{new_resource.release_path}/vendor" do
      action :delete
      recursive true
    end

    link "#{new_resource.release_path}/vendor" do
      to "#{new_resource.path}/shared/vendor"
    end

    execute "#{new_resource.composer_command} install -n -q #{new_resource.composer_options}" do
      cwd new_resource.release_path
      user new_resource.owner
    end

  else
    #direct install
  end

end

action :before_symlink do
end

action :before_restart do
  # If these directories exist in the application, kill them
  %w(app/cache app/logs app/sessions tmp).each do |subdir|
    directory "#{new_resource.release_path}/#{subdir}" do
      owner node[:apache][:user]
      group node[:apache][:group] || node[:apache][:user]
    end

    execute "Change #{subdir} owner to apache2 user" do
      command "chown -R #{node[:apache][:user]}:#{node[:apache][:group] || node[:apache][:user]} #{new_resource.release_path}/#{subdir}"
    end
  end

  execute "php app/console cache:clear" do
    cwd new_resource.release_path
    user node[:apache][:user]
  end
  execute "php app/console cache:warmup" do
    cwd new_resource.release_path
    user node[:apache][:user]
  end
end

action :after_restart do
end

protected

def create_parameters_yml
  host = new_resource.find_database_server(new_resource.database_master_role)

  template "#{new_resource.path}/shared/parameters.yml" do
    source new_resource.parameters_template || "symfony/parameters.yml.erb"
    cookbook new_resource.parameters_template ? new_resource.cookbook_name : "application_php"
    owner new_resource.owner
    group new_resource.group
    mode "644"
    variables(
      :parameters => {
        'parameters' => new_resource.parameters.to_hash
      }
    )

  end

end
