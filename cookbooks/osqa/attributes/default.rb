# MySQL Server IP 
default[:osqa][:sqlserverip] = "localhost"

# MySQL OSQA Account
default[:osqa][:mysql_user_name] = "osqa"
default[:osqa][:mysql_user_password] = "osqapass"

# Apache Server Admin Email
default[:osqa][:server_admin_email] = "email@domain.com"

# Server name without http://
default[:osqa][:server_name] = "domain.com"
default[:osqa][:app_url] = "domain.com"

#default[:osqa][:svn_url] = "http://svn.osqa.net/svnroot/osqa/tags/current-release"
default[:osqa][:svn_url] = "http://svn.osqa.net/svnroot/osqa/trunk/"

default[:osqa][:home_dir] = "/home/osqa/"
default[:osqa][:app_dir] = "/home/osqa/osqa-server"
