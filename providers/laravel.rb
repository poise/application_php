include ApplicationPhpCookbook::ProviderBase

def load_current_resource
  default_database = Mash.new(
    :driver => 'mysql',
    :host => 'localhost',
    :database => 'database',
    :username => 'root',
    :password => '',
    :charset => 'utf8',
    :prefix => ''
  )
  new_resource.database(
    Chef::Mixin::DeepMerge.merge(default_database, new_resource.database)
  )
  new_resource.purge_before_symlink %w(storage)
  new_resource.symlinks 'storage' => 'storage'
  new_resource.symlink_before_migrate 'database.php' => 'application/config/database.php'
end

action :before_compile do
  %w(
    storage/cache storage/database storage/logs storage/sessions 
    storage/views storage/work
  ).each do |dir|
    directory ::File.join(new_resource.path, 'shared', dir) do
      action :create
      recursive true
      owner new_resource.owner
      group new_resource.group
    end
  end
end

protected

def run_before_migrate_setup
  create_configuration_files

  link "#{new_resource.release_path}/application/config/database.php" do
    to "#{new_resource.path}/shared/database.php"
  end
end

def create_configuration_files
  host = new_resource.find_database_server(new_resource.database_master_role)
  new_resource.database[:host] = host if host

  template "#{new_resource.path}/shared/database.php" do
    source new_resource.database_template || "laravel/database.php.erb"
    cookbook new_resource.database_template ? new_resource.cookbook_name.to_s : "application_php"
    owner new_resource.owner
    group new_resource.group
    mode 0644
    variables(
      :database => new_resource.database
    )
  end

end
