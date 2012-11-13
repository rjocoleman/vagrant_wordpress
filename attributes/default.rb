#default attributes.
default['vagrant_wordpress']['webroot'] = "/vagrant/"                        #wordpress dir
default['vagrant_wordpress']['phpinfo_enabled'] = false                      #add an alias for a /phpinfo.php file


#override attributes for our included recipes
override['build_essential']['compiletime'] = true
override['mysql']['server_root_password'] = root
override['mysql']['tunable']['key_buffer'] = "64M"
override['mysql']['tunable']['innodb_buffer_pool_size'] = "32M"
