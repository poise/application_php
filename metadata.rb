name             "application_php"
maintainer       "ZephirWorks"
maintainer_email "andrea.campi@zephirworks.com"
license          "Apache 2.0"
description      "Deploys and configures PHP-based applications"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "2.0.0"

depends "application", "~> 3.0"
depends "apache2"
depends "php"
