Description
===========

Requirements
============

Attributes
==========

Usage
=====

A sample application that needs a database connection:

    application "phpvirtualbox" do
      path "/usr/local/www/sites/phpvirtualbox"
      owner node[:apache][:user]
      group node[:apache][:user]
      repository "..."
      deploy_key "..."
      revision "4_0_7"
      packages ["php-soap"]

      php do
        database_master_role "database_master"
        local_settings_file "config.php"
      end

      mod_php_apache2
    end
