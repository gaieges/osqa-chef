#
# Author:: Paul Chapotet (<paul@scalr.com>)
# Cookbook Name:: osqa
# Recipe:: osqa-apache
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# include the standard recipies
include_recipe "iptables"
include_recipe "apache2"

# add the EPEL repo
yum_repository 'epel' do
  description 'Extra Packages for Enterprise Linux'
  mirrorlist 'http://mirrors.fedoraproject.org/mirrorlist?repo=epel-6&arch=$basearch'
  gpgkey 'http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6'
  action :create
end if platform_family?("rhel")

# Install required system packages
case node['platform_family'] 
when "rhel"
  pkgs = %w[mod_wsgi python-setuptools subversion MySQL-python python-pip]
when "debian"
  pkgs = %w[libapache2-mod-wsgi python-setuptools subversion python-mysqldb python-pip]
end

pkgs.each do |pkg|
  package pkg do
    action :install
  end
end

# create new user group
group "osqa" do
  members node['apache']['user']
  action :create
end

# create new user
user "osqa" do
  comment "OSQA User"
  group "osqa"
  shell "/bin/bash"
  supports :manage_home => true
  action :create
end

# ensure that home dir is setup
directory node[:osqa][:home_dir] do
  owner "osqa"
  group "osqa"
  mode 0770
end

# New vhost for OSQA
web_app "osqa" do
  template "mods/osqa.conf.erb"
  server_name node['fqdn']
  docroot node['osqa']['app_dir']
end


# do some easy installs if needed
%w[South django-debug-toolbar Markdown html5lib python-openid].each do |pkg|
  execute "easy_install[#{pkg}]" do
   command "easy_install #{pkg}"
   action :run
   not_if "pip freeze | grep -q #{pkg}"
  end
end

# Install Django version 1.3.1
execute "pip" do
  command "pip install Django==1.3.1"
  action :run
  not_if "pip freeze | grep -q Django==1.3.1"
end

# Download OSQA code, store in home dir
subversion "osqa-server" do
  repository node[:osqa][:svn_url]
  destination node[:osqa][:app_dir]
  action :sync
end

# New file, mandatory for OSQA
template "#{node[:osqa][:app_dir]}/osqa.wsgi" do
  source "osqa.wsgi.erb"
  mode 0755
end

# OSQA Configuration file
template "#{node[:osqa][:app_dir]}/settings_local.py" do
  source "settings_local.py.erb"
  mode 0755
end


# Populate the OSQA Database
execute "python syncdb" do
  command "python #{node[:osqa][:app_dir]}/manage.py syncdb --all --noinput"
  action :run
  environment ({ 'HOME' => node[:osqa][:app_dir] })
end

# Populate the OSQA Database
execute "python migrate" do
  command "python #{node[:osqa][:app_dir]}/manage.py migrate forum --fake"
  action :run
  environment ( { 'HOME' => node[:osqa][:app_dir] } )
end

# The default directory action is created
directory node[:osqa][:home_dir] do
  owner "osqa"
  group "osqa"
  mode 0750
end

# set writable attribs for the places we need to write to
%W[ forum/upfiles log ].each do |dir|
  directory "#{node[:osqa][:app_dir]}/#{dir}" do
    owner "osqa"
    group "osqa"
    mode 0770
  end
end

# same
file "#{node[:osqa][:app_dir]}/log/django.osqa.log" do
  owner "osqa"
  group "osqa"
  mode 0660
end

# Restart of Apache
service "apache2" do
  action :restart
end

# open the ports to connect 
iptables_rule "osqa"
