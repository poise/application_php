class ApplicationPhpCookbook
  module ResourceBase
    class << self
      def included(klass)
        klass.send(:include, ApplicationCookbook::ResourceBase)
        klass.attribute :database_master_role, :kind_of => String
        klass.attribute :composer, :kind_of => [TrueClass, FalseClass], :default => false
        klass.attribute :composer_command, :kind_of => String, :default => 'composer'
        klass.attribute :composer_options, :kind_of => String
        klass.attribute :pear_packages, :kind_of => [Array, Hash], :default => {}
      end
    end
  end
  module ProviderBase
    class << self
      def included(klass)
        klass.action(:before_deploy) do
          create_configuration_files
        end
        klass.action(:before_migrate) do
          run_before_migrate_setup
          if(new_resource.composer)
            Chef::Log.info 'Running composer install'
            directory "#{new_resource.path}/shared/vendor" do
              owner new_resource.owner
              group new_resource.group
              mode 0755
            end
            directory "#{new_resource.release_path}/vendor" do
              action :delete
              recursive true
            end
            link "#{new_resource.release_path}/vendor" do
              to "#{new_resource.path}/shared/vendor"
            end
            execute "#{new_resource.composer_command} install -n -q #{new_resource.composer_options}" do
              cwd new_resource.release_path
              user new_resource.owner
            end
          else
            unless(new_resource.pear_packages.empty?)
              new_resource.pear_packages.each do |p_pkg, p_ver|
                php_pear p_pkg do
                  action :install
                  version p_ver if p_ver
                end
              end
            end
          end
        end
        # Stub things we probably won't define
        [:before_compile, :before_restart, :before_symlink, :after_restart].each do |key|
          klass.action(key){}
        end
      end
    end

    # Default to log message of no setup
    def run_before_migrate_setup
      Chef::Log.info 'No before migrate setup defined.'
    end

    def create_configuration_files
      Chef::Log.info 'No configuration files defined.'
    end
  end
end
