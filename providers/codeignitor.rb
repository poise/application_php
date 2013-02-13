def load_current_resource
  default_database = Mash.new(
    'hostname' => 'localhost',
    'username' => 'app',
    'password' => 'app',
    'database' => 'app',
    'dbdriver' => 'mysql',
    'pconnect' => true,
    'db_debug' => false,
    'autoinit' => true,
    'stricton' => false
  )
  new_resource.database Chef::Mixin::DeepMerge.merge(default_database, new_resource.database)
  new_resource.purge_before_symlink(
    [::File.join(new_resource.release_path, new_resource.base_prefix, 'logs')]
  )
  new_resource.symlinks.update(
    'logs' => ::File.join('.', new_resource.base_prefix, 'logs')
  )
  new_resource.symlink_before_migrate.update(
    'database.php' => ::File.join('.', new_resource.base_prefix, 'config/database.php')
  )
end

action :before_compile do
  directory File.join(new_resource.path, 'shared', 'logs') do
    action :create
    owner new_resource.owner
    group new_resource.group
  end
end

protected

def create_configuration_files
  host = new_resource.find_database_server(new_resource.database_master_role)

  template "#{new_resource.path}/shared/database.php" do
    source new_resource.database_template || "codeignitor/database.php.erb"
    cookbook new_resource.database_template ? new_resource.cookbook_name : "application_php"
    owner new_resource.owner
    group new_resource.group
    mode 0644
    variables(
      :database => new_resource.database
    )
  end

end

