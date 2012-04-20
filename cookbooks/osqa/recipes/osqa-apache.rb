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

# Install required packages
%w{libapache2-mod-wsgi python-setuptools subversion python-mysqldb python-pip}.each do |pkg|
  package pkg do
    action :install
  end
end

# New user group
group "osqa" do
end

# New user
user "osqa" do
  comment "OSQA User"
  uid 1002
  group "osqa"
  home "/home/osqa"
  shell "/bin/bash"
end

# The default directory action is created
directory "/home/osqa/" do
  owner "osqa"
  group "osqa"
end
directory "/home/osqa/osqa-server/" do
  owner "osqa"
  group "osqa"
end

# We clean up the apache directory
file "/etc/apache2/sites-available/default" do
  action :delete
end
file "/etc/apache2/sites-available/default-ssl" do
  action :delete
end
file "/etc/apache2/sites-enabled/000-default" do
  action :delete
end
file "/etc/apache2/sites-enabled/osqa" do
  action :delete
end
file "/etc/apache2/sites-available/osqa" do
  action :delete
end

# New vhost for OSQA
template "/etc/apache2/sites-available/osqa" do
  source "osqa"
  mode 0755
end

# Symbolic Link to our vhost
execute "ln" do
  command "ln -s /etc/apache2/sites-available/osqa /etc/apache2/sites-enabled/osqa"
  action :run
  environment ({'HOME' => '/home/osqa'})
end

# Required Libraries
execute "easy_install" do
  command "easy_install South django-debug-toolbar markdown \
      html5lib python-openid"
  action :run
  environment ({'HOME' => '/home/osqa'})
end
# Install Django version 1.3.1
execute "pip" do
  command "pip install django==1.3.1"
  action :run
  environment ({'HOME' => '/home/osqa'})
end
# Cleaning OSQA folder in case of a previous version
directory "/home/osqa/osqa-server" do
    action :delete
    recursive true
end
directory "/home/osqa/osqa-server/" do
  owner "osqa"
  group "osqa"
end

# Download OSQA
execute "svn" do
  command "svn co http://svn.osqa.net/svnroot/osqa/trunk/ /home/osqa/osqa-server"
  action :run
  environment ({'HOME' => '/home/osqa'})
end

# New file, mandatory for OSQA
template "/home/osqa/osqa-server/osqa.wsgi" do
  source "osqa.wsgi"
  mode 0755
end

# OSQA Configuration file
template "/home/osqa/osqa-server/settings_local.py" do
  source "settings_local.py"
  mode 0755
end

# Populate the OSQA Database
execute "python syncdb" do
  command "python /home/osqa/osqa-server/manage.py syncdb --all"
  action :run
  environment ({'HOME' => '/home/osqa/osqa-server'})
end
# Populate the OSQA Database
execute "python migrate" do
  command "python /home/osqa/osqa-server/manage.py migrate forum --fake"
  action :run
  environment ({'HOME' => '/home/osqa/osqa-server'})
end
# Rights
execute "chown osqa server" do
  command "chown -R osqa:www-data /home/osqa/osqa-server"
  action :run
  environment ({'HOME' => '/home/osqa/osqa-server'})
end
execute "chmod upfile" do
  command "chmod -R g+w /home/osqa/osqa-server/forum/upfiles"
  action :run
  environment ({'HOME' => '/home/osqa/osqa-server'})
end
execute "chmod log" do
  command "chmod -R g+w /home/osqa/osqa-server/log"
  action :run
  environment ({'HOME' => '/home/osqa/osqa-server'})
end
# Restart of Apache
service "apache2" do
  action :restart
end