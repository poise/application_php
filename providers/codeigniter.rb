include ApplicationPhpCookbook::ProviderBase

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
  new_resource.symlinks.update(
    'logs' => ::File.join('.', new_resource.base_prefix, 'logs'),
    'cache' => ::File.join('.', new_resource.base_prefix, 'cache')
  )
  new_resource.symlink_before_migrate.update(
    'database.php' => ::File.join('.', new_resource.base_prefix, 'config/database.php')
  )
  new_resource.purge_before_symlink(%W(
    #{::File.join('.', new_resource.base_prefix, 'logs')}
    #{::File.join('.', new_resource.base_prefix, 'cache')}
  ))
end

action :before_compile do
  directory ::File.join(new_resource.path, 'shared', 'logs') do
    owner new_resource.owner
    group new_resource.group
  end
  directory ::File.join(new_resource.path, 'shared', 'cache') do
    owner new_resource.owner
    group new_resource.group
  end
end

protected

def create_configuration_files
  host = new_resource.find_database_server(new_resource.database_master_role)
  new_resource.database[:hostname] = host if host

  template "#{new_resource.path}/shared/database.php" do
    source new_resource.database_template || "codeigniter/database.php.erb"
    cookbook new_resource.database_template ? new_resource.cookbook_name.to_s : "application_php"
    owner new_resource.owner
    group new_resource.group
    mode 0644
    variables(
      :database => new_resource.database
    )
  end

end

