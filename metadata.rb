name "vagrant_wordpress"
version "0.0.7"
description "A Chef cookbook for deployment of Wordpress with Vagrant."

supports "ubuntu"

depends "apt"
depends "build-essential"
depends "git"
depends "mysql"
depends "database"
depends "php"
depends "apache2"

recipe "vagrant_wordpress", "Main configuration for Wordpress"