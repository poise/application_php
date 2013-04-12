include Chef::Resource::ApplicationPhpBase

attribute :database, :kind_of => Hash
attribute :database_template, :kind_of => String
attribute :base_prefix, :kind_of => String, :default => ''
