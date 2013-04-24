#default attributes.
default['vagrant_wordpress']['webroot'] = "/vagrant/"                      #wordpress dir
default['vagrant_wordpress']['phpinfo_enabled'] = false                    #add an alias for a /phpinfo.php file
default['vagrant_wordpress']['mailcatcher'] = false                        #install mailcatcher (http://mailcatcher.me)
default['vagrant_wordpress']['ioncube_loader'] = false                     #install ioncube-loader

default['vagrant_wordpress']['environment']['DB_HOST'] = "localhost"       #required, Database Host
default['vagrant_wordpress']['environment']['DB_NAME'] = "wordpress"       #required, Database Name
default['vagrant_wordpress']['environment']['DB_USER'] = "root"            #required, Database User Name
default['vagrant_wordpress']['environment']['DB_PASS'] = "root"            #required, Database User Password

#override attributes for our included recipes
override['build_essential']['compiletime'] = true
override['mysql']['allow_remote_root'] = true
override['mysql']['tunable']['key_buffer'] = "64M"
override['mysql']['tunable']['innodb_buffer_pool_size'] = "32M"

override['mysql']['server_root_password'] = node['vagrant_wordpress']['environment']['DB_PASS']
node['mysql']['server_repl_password'] = "root"
node['mysql']['server_debian_password'] = "root"