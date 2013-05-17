#
# Cookbook Name:: jenkins
# Recipe:: default
#
# Copyright 2013, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe "tomcat"

service node["tomcat"]["version"] do
    action :stop
end

execute "remove ROOT folder from tomcat" do
    not_if { File.exists?("#{node["tomcat"]["webapps_dir"]}/ROOT.war")}
    cwd node["tomcat"]["webapps_dir"]
    command "sudo rm -rf ROOT"
end

remote_file "#{node["tomcat"]["webapps_dir"]}/ROOT.war" do
    source node["jenkins"]["url"]
    mode "0644"
    action :create_if_missing
end

bash "set up jenkins" do
    user "root"
    cwd  node["tomcat"]["home"]
    code <<-EOH
        mkdir .jenkins
        chown #{node["tomcat"]["user"]}:#{node["tomcat"]["group"]} .jenkins
        mkdir .rvm
        chown #{node["tomcat"]["user"]}:#{node["tomcat"]["group"]} .rvm
        mkdir .jenkins/plugins
        chown #{node["tomcat"]["user"]}:#{node["tomcat"]["group"]} .jenkins/plugins
    EOH
end

node["jenkins"]["plugins"].each do |name|
    remote_file "#{node["tomcat"]["home"]}/#{node["jenkins"]["home_dir"]}/plugins/#{name}.hpi" do
        source "#{node["jenkins"]["mirror"]}/latest/#{name}.hpi"
        backup false
        owner node["tomcat"]["user"]
        group node["tomcat"]["group"]
        action :create_if_missing
    end
end

template "#{node["tomcat"]["home"]}/#{node["jenkins"]["home_dir"]}/config.xml" do
    source "config.xml.erb"
    owner node["tomcat"]["user"]
    group node["tomcat"]["group"]
    mode "0644"
end

service node["tomcat"]["version"] do
    action :restart
end
