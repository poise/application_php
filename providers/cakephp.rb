def load_current_resource
  new_resource.composer_command node[:php][:composer][:exec] unless new_resource.composer_command
  if(new_resource.database.nil?)
    new_resource.database(
      'datasource' => 'Database/Mysql',
      'persistent' => false,
      'host' => 'localhost',
      'login' => 'app',
      'password' => 'app',
      'database' => 'app',
      'prefix' => '',
      'encoding' => 'utf8'
    )
  end
end

action :before_compile do
  new_resource.symlink_before_migrate.update(
    'database.php' => 'app/Config/database.php'
  )
end

action :before_deploy do
  create_database_php
  set_production_in_core
end

action :before_migrate do

  link "#{new_resource.release_path}/app/Config/database.php" do
    to "#{new_resource.path}/shared/database.php"
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
  %w(tmp).each do |subdir|
    directory "#{new_resource.release_path}/#{subdir}" do
      owner node[:apache][:user]
      group node[:apache][:group] || node[:apache][:user]
    end

    execute "Change #{subdir} owner to apache2 user" do
      command "chown -R #{node[:apache][:user]}:#{node[:apache][:group] || node[:apache][:user]} #{new_resource.release_path}/#{subdir}"
    end
  end
end

action :after_restart do
end

protected

def create_database_php
  host = new_resource.find_database_server(new_resource.database_master_role)

  template "#{new_resource.path}/shared/database.php" do
    source new_resource.parameters_template || "cakephp/database.php.erb"
    cookbook new_resource.parameters_template ? new_resource.cookbook_name : "application_php"
    owner new_resource.owner
    group new_resource.group
    mode 0644
    variables(
      :database => new_resource.database
    )
  end

end

def set_production_in_core
  file = Chef::Util::FileEdit.new("#{new_resource.release_path}/app/Config/core.php")
  file.search_file_replace(%r{'debug',\s*1}, "'debug', 0")
  file.write_file
end
