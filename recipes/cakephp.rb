remote_path = "http://github.com/cakephp/cakephp/tarball/#{node[:application_php][:cakephp][:version]}"
local_path = File.join(node[:application_php][:cakephp][:install_dir], "cake-#{node[:application_php][:cakephp][:version]}.tar.gz")
final_dir = File.join(node[:application_php][:cakephp][:install_dir], node[:application_php][:cakephp][:version])

directory final_dir do
  recursive true
end

remote_file local_path do
  source remote_path
  action :create_if_missing
end

execute "unpack cakephp v#{node[:application_php][:cakephp][:version]}" do
  command "tar -xzf #{File.basename(local_path)}"
  cwd File.dirname(local_path)
  creates File.join(final_dir, 'index.php')
end

execute "install cakephp v#{node[:application_php][:cakephp][:version]}" do
  command "mv cakephp-cakephp-*/* #{final_dir}/"
  cwd File.dirname(local_path)
  creates File.join(final_dir, 'index.php')
end

node.set[:php][:ini_defaults][:PHP][:include_path] = ".:/usr/share/php:/usr/share/pear:#{final_dir}/lib"
