chef-ejabberd
=============

A Chef cookbook for ejabberd with the mysql native driver

Create a directory in your chef cookbooks called jabber

Add an attributes file at cookbooks/jabber/attributes/default.rb :-

```
node.default[:jabber_domain] = 'xmpp.mydomain.com'
node.default[:jabber_user] = 'ejabberd'
node.default[:jabber_password] = 'password'

node.default[:mysql_hostname] = 'ec2.somewhere.in.rds.maybe'
node.default[:mysql_databasename] = 'xmpp'
node.default[:mysql_username] = 'xmpp'
node.default[:mysql_password] = 'password'
```
