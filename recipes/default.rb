package "ejabberd"

service "ejabberd" do
  action :enable
  supports :restart => true
end

template "/etc/ejabberd/ejabberd.cfg" do
  source "ejabberd.cfg.erb"
  owner "ejabberd"
  variables({
    :jabber_domain => node[:jabber_domain],
    :mysql_hostname => node[:mysql_hostname],
    :mysql_databasename => node[:mysql_databasename],
    :mysql_username => node[:mysql_username],
    :mysql_password => node[:mysql_password]
  })
  notifies :restart, resources(:service => "ejabberd")
end

# execute "add ejabberd admin user" do
#   command "ejabberdctl register admin #{node[:base][:jabber_domain]} #{node[:base][:jabber_admin_password]}"
# end

service "ejabberd" do
  action :start
end

package "nginx"

service "nginx" do
  action :start
end

