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

# Create a new osqa user if doesn't exist
execute "create osqa user" do
  command "/usr/bin/mysql -u #{node[:osqa][:mysql_admin_username]} -p#{node[:osqa][:mysql_admin_password]} -D mysql -r -B -N -e \"CREATE USER '#{node[:osqa][:mysql_user_name]}'@'%'\""
  not_if "/usr/bin/mysql -u #{node[:osqa][:mysql_admin_username]} -p#{node[:osqa][:mysql_admin_password]} -D mysql -r -B -N -e \"SELECT * FROM user where User='#{node[:osqa][:mysql_user_name]}' and Host = '%'\" | grep -q #{node[:osqadb][:mysql_user_name]}"
end

# Update his password
execute "set password for osqa" do
  command "/usr/bin/mysql -u #{node[:osqa][:mysql_admin_username]} -p#{node[:osqa][:mysql_admin_password]} -D mysql -r -B -N -e \"SET PASSWORD FOR '#{node[:osqa][:mysql_user_name]}'@'%' = PASSWORD('#{node[:osqa][:mysql_user_password]}')\""
end

# Remove existing osqa database
execute "remove existing osqa database" do
  command "/usr/bin/mysql -u #{node[:osqa][:mysql_admin_username]} -p#{node[:osqa][:mysql_admin_password]} -D mysql -r -B -N -e \"DROP DATABASE IF EXISTS osqa\""
end

# Create a new osqa database
execute "create new osqa database" do
  command "/usr/bin/mysql -u #{node[:osqa][:mysql_admin_username]} -p#{node[:osqa][:mysql_admin_password]} -D mysql -r -B -N -e \"CREATE DATABASE osqa DEFAULT CHARACTER SET UTF8 COLLATE utf8_general_ci\""
end

# Grant rights to osqa user on osqa database
execute "grant user all rights" do
  command "/usr/bin/mysql -u #{node[:osqa][:mysql_admin_username]} -p#{node[:osqa][:mysql_admin_password]} -D mysql -r -B -N -e \"GRANT ALL on osqa.* to '#{node[:osqa][:mysql_user_name]}'@'%'\""
end