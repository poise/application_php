include Chef::Resource::ApplicationBase

attribute :database_master_role, :kind_of => [String, NilClass], :default => nil
attribute :composer, :kind_of => [TrueClass, FalseClass], :default => false
attribute :composer_command, :kind_of => String
attribute :composer_options, :kind_of => String
attribute :database, :kind_of => Hash
