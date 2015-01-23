bash "add erlang source to apt sources" do
  code <<-EOH
    echo 'deb http://packages.erlang-solutions.com/debian precise contrib' >> /etc/apt/sources.list
    wget -O - http://packages.erlang-solutions.com/debian/erlang_solutions.asc | apt-key add -
  EOH
  not_if "grep asdfsdf /etc/apt/sources.list"
end

bash "update apt" do
  code "apt-get update"
end

package "esl-erlang" do
  action :install
end



package "git-core" do
  action :install
end


git '/usr/local/src/rebar' do
  repository 'git://github.com/rebar/rebar.git'
end

bash "install rebar" do
  code <<-EOH
    cd /usr/local/src/rebar
    ./bootstrap
    cp rebar /usr/bin/
  EOH
end



group 'ejabberd'
user 'ejabberd' do
  group 'ejabberd'
	supports :manage_home => true
	home '/home/ejabberd'
end

[
  "build-essential",
	"autoconf",
	"libyaml-dev",
  "libssl-dev",
  "libexpat1-dev",
  "zlib1g-dev",
].each do |pkg|
  package pkg do
    action :install
  end
end

git '/usr/local/src/ejabberd' do
  repository 'https://github.com/processone/ejabberd.git'
	reference "#{node[:git_checkout_tag]}"
end

bash "compile ejabberd" do
  code <<-EOH
    cd /usr/local/src/ejabberd
		./autogen.sh
    ./configure --enable-mysql --prefix=/usr --enable-user=ejabberd --sysconfdir=/etc --localstatedir=/var --libdir=/usr/lib
		make
		make doc
    make install
  EOH
end

git '/usr/local/src/p1_mysql' do
  repository 'https://github.com/processone/mysql'
	reference '42e8d4c2c38e32358235fe42136c6433fa5aa83e'
end

bash "install ejabberd mysql" do
  code <<-EOH
    cd /usr/local/src/p1_mysql
    make
    cp ebin/* /usr/lib/ejabberd/ebin/
  EOH
end

bash "get and build rebar deps" do
	code <<-EOH
	  cd /usr/local/src/ejabberd
		./rebar get-deps
		./rebar compile
		cp -R deps/* /usr/lib/ejabberd/include/
	EOH
end

git '/usr/local/src/ejabberd-contrib' do
  repository 'git://github.com/processone/ejabberd-contrib.git'
end

bash "install mod_admin_extra" do
  code <<-EOH
    cd /usr/local/src/ejabberd-contrib/mod_admin_extra
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

template "/etc/ejabberd/ejabberd.yml" do
  source "ejabberd.yml.erb"
  owner "ejabberd"
  variables({
    :jabber_hosts       => node[:jabber_hosts],
    :jabber_domain      => node[:jabber_domain],
    :mysql_hostname     => node[:mysql_hostname],
    :mysql_databasename => node[:mysql_databasename],
    :mysql_username     => node[:mysql_username],
    :mysql_password     => node[:mysql_password]
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

package "nginx"

service "nginx" do
  action :start
end

cookbook_file "ejabberd.example.pem" do
  path "/etc/ejabberd/ejabberd.pem"
  owner "ejabberd"
  group "ejabberd"
  mode "600"
  action :create
end


# mod_zeropush

git '/usr/local/src/ejabberd-contrib/mod_zeropush' do
  repository 'https://github.com/ZeroPush/mod_zeropush.git'
	reference "v#{node[:git_checkout_tag]}"
end

template '/usr/local/src/ejabberd-contrib/mod_zeropush/Emakefile' do
  source 'mod_zeropush-Emakefile.erb'
  variables({
    :zeropush_token => node[:zeropush_token]
	})
end

bash "install mod_zeropush" do
  code <<-EOH
	  cd /usr/local/src/ejabberd-contrib/mod_zeropush
		./build.sh
    cp ebin/* /usr/lib/ejabberd/ebin
	EOH
end

# end mod_zeropush


service "ejabberd" do
  action [:enable, :start]
  supports :restart => true
end

