#
# Cookbook Name:: application_php
# Resource:: php
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

include ApplicationPhpCookbook::ResourceBase

attribute :write_settings_file, :kind_of => [TrueClass, FalseClass], :default => true
attribute :local_settings_file, :kind_of => [String, NilClass], :default => 'LocalSettings.php'
# Actually defaults to "#{local_settings_file_name}.erb", but nil means it wasn't set by the user
attribute :settings_template, :kind_of => [String, NilClass], :default => nil
attribute :packages, :kind_of => [Array, Hash], :default => []
attribute :app_root, :kind_of => String, :default => "/"
attribute :replace_database_info_file, :kind_of => String

def local_settings_file_name
  @local_settings_file_name ||= local_settings_file.split(/[\\\/]/).last
end

def database(*args, &block)
  @database ||= Mash.new
  @database.update(options_block(*args, &block))
end
