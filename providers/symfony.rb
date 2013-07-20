include ApplicationPhpCookbook::ProviderBase

def load_current_resource
  default_params = Mash.new(
    :database_driver => 'pdo_mysql',
    :database_host => 'localhost',
    :database_name => 'symfony',
    :database_user => 'symfony',
    :database_password => 'symfony',
    :mailer_transport => 'smtp',
    :mailer_host => 'localhost',
    :mailer_user => 'symfony',
    :mailer_password => 'symfony',
    :locale => 'en',
    :secret => 'CHANGEME'
  )
  new_resource.parameters Chef::Mixin::DeepMerge.merge(default_params, new_resource.parameters)
  new_resource.purge_before_symlink %w(app/cache app/logs app/sessions tmp)
  new_resource.symlinks.update(
    'cache' => 'app/cache',
    'logs' => 'app/logs',
    'sessions' => 'app/sessions',
    'tmp' => 'tmp'
  )
  new_resource.symlink_before_migrate.update(
    'parameters.yml' => 'app/config/parameters.yml'
  )
end

action :before_compile do
  %w(cache logs sessions tmp).each do |dir|
    directory ::File.join(new_resource.path, 'shared', dir) do
      owner new_resource.owner
      group new_resource.group
      recursive true
    end
  end
end

action :before_restart do

  execute "php app/console cache:clear" do
    cwd new_resource.release_path
    user new_resource.owner
  end

  execute "php app/console cache:warmup" do
    cwd new_resource.release_path
    user new_resource.owner
  end

end

protected

def run_before_migrate_setup
  create_configuration_files
  link "#{new_resource.release_path}/app/config/parameters.yml" do
    to "#{new_resource.path}/shared/parameters.yml"
  end
end

def create_configuration_files
  host = new_resource.find_database_server(new_resource.database_master_role)
  new_resource.parameters[:database_host] = host if host

  template "#{new_resource.path}/shared/parameters.yml" do
    source new_resource.parameters_template || "symfony/parameters.yml.erb"
    cookbook new_resource.parameters_template ? new_resource.cookbook_name.to_s : "application_php"
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
