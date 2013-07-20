#
# Cookbook Name:: application_php
# Provider:: php
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

include ApplicationPhpCookbook::ProviderBase
include Chef::Mixin::LanguageIncludeRecipe

def load_current_resource
  if(new_resource.pear_packages.empty? && !new_resource.packages.empty?)
    new_resource.pear_packages new_resource.packages
  end
end

action :before_compile do
  include_recipe 'php'
  if(new_resource.write_settings_file)
    new_resource.local_settings_file 'LocalSettings.php' unless new_resource.local_settings_file
    new_resource.symlink_before_migrate[new_resource.local_settings_file_name] ||= new_resource.local_settings_file
  end
end

action :before_migrate do
  if(new_resource.replace_database_info_file)
    replace_db_info!
  end
end

protected

def search_for_database
  host = new_resource.find_database_server(new_resource.database_master_role)
  new_resource.database[:host] = host if host
end

def create_configuration_files
  if(new_resource.write_settings_file)
    search_for_database
    template "#{new_resource.path}/shared/#{new_resource.local_settings_file_name}" do
      source new_resource.settings_template || "#{new_resource.local_settings_file_name}.erb"
      owner new_resource.owner
      group new_resource.group
      mode "644"
      variables(
        :path => "#{new_resource.path}/current",
        :database => new_resource.database
      )
    end
  end
end

def replace_db_info!
  search_for_database
  path = ::File.join(new_resource.release_path, new_resource.replace_database_info_file)
  if(::File.exists?(path))
    Chef::Log.warn "Editing file: #{path}"
    file = Chef::Util::FileEdit.new(path)
    new_resource.database.each do |key, value|
      file.search_file_replace(%r{%%#{key}%%}, value)
    end
    file.write_file
  else
    raise "Failed to locate requested file to apply database configuration information (#{path})"
  end
end
