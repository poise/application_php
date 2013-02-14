include Chef::Resource::ApplicationPhpBase

attribute :database_template, :kind_of => String
attribute :database, :kind_of => Hash, :default => {}
