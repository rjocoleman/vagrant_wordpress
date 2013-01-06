include_recipe "apt"
include_recipe "build-essential"
include_recipe "git"
include_recipe "mysql::server"
include_recipe "mysql::ruby"
include_recipe "php"
include_recipe "php::module_mysql"
include_recipe "php::module_gd"
include_recipe "php::module_curl"
include_recipe "apache2"
include_recipe "apache2::mod_php5"
include_recipe "apache2::mod_rewrite"

#install apt packages
%w{zip libpcre3-dev libsqlite3-dev}.each do |pkg|
  package pkg do
    action :upgrade
  end
end

#install the zip pecl
php_pear "zip" do
  action :install
end

#disable default virtualhost.
apache_site "default" do
  enable false
  notifies :restart, "service[apache2]"
end

#create a virtualhost that's mapped to our shared folder and hostname.
web_app "wordpress_dev" do
  server_name node['hostname']
  server_aliases node['fqdn'], node['host_name']
  docroot node['vagrant_wordpress']['webroot']
  
  notifies :restart, "service[apache2]", :immediately
end

#create a phpinfo file for use in our Apache vhost
template "/var/www/phpinfo.php" do
  mode "0644"
  source "phpinfo.php.erb"
  
  not_if { node['vagrant_wordpress']['phpinfo_enabled'] == false }
  notifies :restart, "service[apache2]", :immediately
end

#create a mysql database
mysql_database node['vagrant_wordpress']['environment']['DB_NAME'] do
  connection ({:host => "localhost", :username => 'root', :password => node['mysql']['server_root_password']})
  action :create
end

#add environment variables
ruby_block "append_env_variables" do
  block do
    file = Chef::Util::FileEdit.new("/etc/environment")
    node['vagrant_wordpress']['environment'].each do |a,b|    
      file.insert_line_if_no_match("/#{a}=/", "#{a}=#{b}")
    end
    file.write_file
  end
end

#add mailcatcher if it's enabled
gem_package "mailcatcher" do
  not_if { node['vagrant_wordpress']['mailcatcher'] == false }
  
  action :install
end

# Get eth1 ip
eth1_ip = node['network']['interfaces']['eth1']['addresses'].select{|key,val| val['family'] == 'inet'}.flatten[0]

# Setup MailCatcher
bash "mailcatcher" do
  code "mailcatcher --http-ip #{eth1_ip}"
  
  not_if { node['vagrant_wordpress']['mailcatcher'] == false }
end

template "#{node['php']['ext_conf_dir']}/mailcatcher.ini" do
  source "mailcatcher.ini.erb"
  owner "root"
  group "root"
  mode "0644"
  action :create
  notifies :restart, resources("service[apache2]"), :delayed
  
  not_if { node['vagrant_wordpress']['mailcatcher'] == false }
end