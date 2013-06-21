# TODO: remove the unnecessary items from here
%w{build-essential m4 libncurses5-dev libssh-dev unixodbc-dev libgmp3-dev libwxgtk2.8-dev libglu1-mesa-dev fop xsltproc default-jdk libexpat1-dev libxml2-utils git-core}.each do |pkg|
  package pkg do
    action :install
  end
end

remote_file "#{Chef::Config[:file_cache_path]}/esl-erlang_16.b-2~ubuntu~precise_amd64.deb" do
  source "https://elearning.erlang-solutions.com/couchdb//rbingen_adapter//package_R16B_precise64_1361901944/esl-erlang_16.b-2~ubuntu~precise_amd64.deb"
end

dpkg_package "erlang" do
  source "#{Chef::Config[:file_cache_path]}/esl-erlang_16.b-2~ubuntu~precise_amd64.deb"
end

bash "install rebar" do
  code <<-EOH
    cd ~/
    git clone git://github.com/rebar/rebar.git
    cd rebar/
    ./bootstrap
    cp rebar /usr/bin/
  EOH
end

bash "compile ejabberd" do
  code <<-EOH
    cd ~/
    git clone git://git.process-one.net/ejabberd/mainline.git ejabberd
    cd ejabberd
    git checkout -b 2.1.x origin/2.1.x
    cd src
    ./configure --enable-odbc --prefix=/usr --enable-user=ejabberd --sysconfdir=/etc --localstatedir=/var --libdir=/usr/lib
    make install
  EOH
end

bash "install ejabberd mysql" do
  code <<-EOH
    cd ~/
    git clone https://github.com/processone/mysql
    cd mysql/
    make
    cp ebin/* /usr/lib/ejabberd/ebin/
  EOH
end

bash "install mod_admin_extra" do
  code <<-EOH
    git clone git://github.com/processone/ejabberd-contrib.git
    git checkout 2.1.x
    cd ejabberd-contrib/mod_admin_extra/
    ./build.sh
    cp ebin/* /usr/lib/ejabberd/ebin
  EOH
end

template "/etc/init.d/ejabberd" do
  owner 'root'
  group 'root'
  mode 0755
  source "init.d/ejabberd.erb"
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
end

template "/etc/ejabberd/ejabberdctl.cfg" do
  source "ejabberdctl.cfg.erb"
  owner "ejabberd"
end

template "/etc/ejabberd/inetrc" do
  source "inetrc.erb"
  owner "ejabberd"
end

# execute "add ejabberd admin user" do
#   command "ejabberdctl register admin #{node[:base][:jabber_domain]} #{node[:base][:jabber_admin_password]}"
# end

package "nginx"

service "nginx" do
  action :start
end

service "ejabberd" do
  action :enable
  supports :restart => true
end
