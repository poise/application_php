include ApplicationPhpCookbook::ProviderBase

def load_current_resource
  default_database = Mash.new(
    'datasource' => 'Database/Mysql',
    'persistent' => false,
    'host' => 'localhost',
    'login' => 'app',
    'password' => 'app',
    'database' => 'app',
    'prefix' => '',
    'encoding' => 'utf8'
  )
  new_resource.database Chef::Mixin::DeepMerge.merge(default_database, new_resource.database)
  new_resource.purge_before_symlink %w(tmp)
  new_resource.symlinks.update('tmp' => 'tmp')
  new_resource.symlink_before_migrate.update('database.php' => 'Config/database.php')
end

action :before_compile do
  %w(tmp/logs tmp/cache/models tmp/cache/persistent tmp/cache/queries).each do |dir|
    directory ::File.join(new_resource.path, 'shared', dir) do
      owner new_resource.owner
      group new_resource.group
      recursive true
    end
  end
end

protected

def create_configuration_files
  host = new_resource.find_database_server(new_resource.database_master_role)
  new_resource.database[:host] = host if host

  template "#{new_resource.path}/shared/database.php" do
    source new_resource.database_template || "cakephp/database.php.erb"
    cookbook new_resource.database_template ? new_resource.cookbook_name.to_s : "application_php"
    owner new_resource.owner
    group new_resource.group
    mode 0644
    variables(
      :database => new_resource.database
    )
  end

end

def set_production_in_core
  Chef::Log.warn "Editing file: #{new_resource.release_path}/Config/core.php"
  file = Chef::Util::FileEdit.new("#{new_resource.release_path}/Config/core.php")
  file.search_file_replace(%r{'debug',\s*1}, "'debug', 0")
  file.write_file
end

def run_before_migrate_setup
  set_production_in_core
  create_configuration_files
  link "#{new_resource.release_path}/Config/database.php" do
    to "#{new_resource.path}/shared/database.php"
  end
end
