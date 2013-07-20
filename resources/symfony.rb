include ApplicationPhpCookbook::ResourceBase

attribute :database_master_role, :kind_of => [String, NilClass], :default => nil
attribute :parameters_template, :kind_of => String
attribute :parameters, :kind_of => Hash, :default => {}
