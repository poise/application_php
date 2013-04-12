#
# Cookbook Name:: application_php
# Provider:: mod_php_apache2
#
# Copyright 2012, ZephirWorks
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include Chef::Mixin::LanguageIncludeRecipe

action :before_compile do

  include_recipe "apache2"
  include_recipe "apache2::mod_rewrite"
  include_recipe "apache2::mod_deflate"
  include_recipe "apache2::mod_headers"
  include_recipe "apache2::mod_php5"

  unless new_resource.server_aliases
    server_aliases = [ "#{new_resource.application.name}.#{node['domain']}", node['fqdn'] ]
    if node.has_key?("cloud")
      server_aliases << node['cloud']['public_hostname']
    end
    new_resource.server_aliases server_aliases
  end

  unless new_resource.restart_command
    new_resource.restart_command do
      run_context.resource_collection.find(:service => "apache2").run_action(:restart)
    end
  end

end

action :before_deploy do

  new_resource = @new_resource

  web_app new_resource.application.name do
    docroot "#{new_resource.application.path}/current#{new_resource.app_root}"
    template new_resource.webapp_template || 'php.conf.erb'
    cookbook new_resource.webapp_template ? new_resource.cookbook_name.to_s : "application_php"
    server_name "#{new_resource.application.name}.#{node['domain']}"
    server_aliases new_resource.server_aliases
    log_dir node['apache']['log_dir']
    if(new_resource.webapp_overrides)
      new_resource.webapp_overrides.each do |attribute, value|
        self.send(attribute, value)
      end
    end
  end

  apache_site "000-default" do
    enable false
  end

end

action :before_migrate do
end

action :before_symlink do
end

action :before_restart do
end

action :after_restart do
end
