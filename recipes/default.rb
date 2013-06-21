package "ejabberd"

%w{build-essential m4 libncurses5-dev libssh-dev unixodbc-dev libgmp3-dev libwxgtk2.8-dev libglu1-mesa-dev fop xsltproc default-jdk libexpat1-dev libxml2-utils}.each do |pkg|
  package pkg do
    action :install
  end
end

bash "compile ejabberd" do
  code <<-EOH
    mkdir -p /src/erlang
    cd /src/erlang
    wget http://www.erlang.org/download/otp_src_R16B.tar.gz
    tar -xvzf otp_src_R16B.tar.gz
    chmod -R 777 otp_src_R16B
    cd otp_src_R16B
    ./configure --prefix=/usr && make && make install

    cd ~/
    git clone git://github.com/rebar/rebar.git
    cd rebar/
    ./bootstrap
    cp rebar /usr/bin/

    cd ~/
    git clone git://git.process-one.net/ejabberd/mainline.git ejabberd
    cd ejabberd
    git checkout -b 2.1.x origin/2.1.x
    cd src
    ./configure --enable-odbc --prefix=/usr --enable-user=ejabberd --sysconfdir=/etc --localstatedir=/var --libdir=/usr/lib
    make install

    cd ~/
    git clone https://github.com/processone/mysql
    cd mysql/
    make
    cp ebin/* /usr/lib/ejabberd/ebin/
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
