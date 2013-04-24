include_recipe "apt"
include_recipe "build-essential"
include_recipe "git"
include_recipe "mysql::server"
include_recipe "mysql::ruby"
include_recipe "php"
include_recipe "apache2"
include_recipe "apache2::mod_php5"
include_recipe "apache2::mod_rewrite"

chef_gem "versionomy"
require "versionomy"

class Chef::Resource
  include LampHelper
end

#install apt packages
%w{zip libpcre3-dev libsqlite3-dev php5-mysql php5-gd php5-curl}.each do |pkg|
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

#ioncube loader
ruby_block "ioncube-loader" do
  block do
    # doing nothing, hack to do this ioncube stuff at convergence so that we can look at PHP's versions etc.
  end
  action :create
  
  not_if { node['vagrant_wordpress']['ioncube_loader'] == false }
  only_if { `which php` != false }
  
  notifies :create, "remote_file[#{Chef::Config[:file_cache_path]}/ioncube_loader.tar.gz]", :immediately
  notifies :run, "execute[ioncube-loader-extract]", :immediately
  notifies :run, "execute[ioncube-loader-copy]", :immediately
  notifies :create, "template[#{node['php']['ext_conf_dir']}/ioncube-loader.ini]", :immediately
end

case node["os"]
when "linux" # only on linux, for now... 
  remote_file "#{Chef::Config[:file_cache_path]}/ioncube_loader.tar.gz" do
    if node['kernel']['machine'] =~ /x86_64/
      source "http://downloads2.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz"
    else
      source "http://downloads2.ioncube.com/loader_downloads/ioncube_loaders_lin_x86.tar.gz"
    end
    
    backup false
    mode "0644"
    
    action :nothing
  end
  
  #extract ioncube loader
  execute "ioncube-loader-extract" do
    cwd Chef::Config[:file_cache_path]
    command "tar zxf #{Chef::Config[:file_cache_path]}/ioncube_loader.tar.gz"
    
    action :nothing
  end
  
  #install ioncube loader
  execute "ioncube-loader-copy" do
    command "cp -r #{Chef::Config[:file_cache_path]}/ioncube/ioncube_loader_lin_#{get_php_version}.so #{get_php_extension_dir}"
    
    action :nothing
  end
  
  template "#{node['php']['ext_conf_dir']}/ioncube-loader.ini" do
    source "ioncube-loader.ini.erb"
    owner "root"
    group "root"
    mode "0644"
    variables(:php_version => lambda do return LampHelper.get_php_version end, :php_extension_dir => lambda { return system("/usr/bin/php-config --extension-dir") })
    
    action :nothing
    notifies :restart, resources("service[apache2]"), :delayed
  end
end