#
# Author:: Paul Chapotet (<paul@scalr.com>)
# Cookbook Name:: osqa
# Recipe:: osqa-database
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

# bug with debian boxes - need to ensure up to date repos
execute "apt-get-update" do
  command "apt-get update"
  action :run
end if platform_family?("debian")

package "make"
gem_package "mysql"

# add the right recipies
include_recipe "mysql::server"
include_recipe "database"

# we'll use this connection a few times
mysql_root_connection = {
  :host     => node[:osqa][:sqlserverip],
  :username => 'root',
  :password => node['mysql']['server_root_password']
}

# add the db
mysql_database 'osqa' do
  connection mysql_root_connection
  action :create
end

# add the user to that db
mysql_database_user 'osqa' do
  connection mysql_root_connection
  password node[:osqa][:mysql_user_password]
  database_name 'osqa'
  host node[:osqa][:sqlserverip]
  privileges [:all]
  action [:create, :grant]
end
