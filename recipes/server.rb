include_recipe "apache2"

package "nagios3"
package "nagios-nrpe-plugin"

# required for Solr plugin
gem_package "xml-simple"
gem_package "choice"

gem_package "tinder"
gem_package "clickatell"
gem_package "xmpp4r-simple"

user "nagios" do
  action :manage
  home "/etc/nagios3"
  shell "/bin/bash"
end

execute "copy distribution init.d script" do
  command "mv /etc/init.d/nagios3 /etc/init.d/nagios3.dist"
  creates "/etc/init.d/nagios3.dist"
end

directory "/etc/nagios3/.ssh" do
  mode 0700
  owner "nagios"
  group "nagios"
end

file "/etc/nagios3/htpasswd.users" do
  owner "nagios"
  group "www-data"
  mode 0750
  action :create
end

directory "/var/lib/nagios3" do
  mode 0755
end

directory "/var/lib/nagios3/rw" do
  group "www-data"
  mode 02775
end

# Support our legacy nagios install
directory "/usr/local/nagios"

link "/usr/local/nagios/libexec" do
  to "/usr/lib/nagios/plugins"
end

link "/bin/mail" do
  to "/usr/bin/mailx"
end

link "/usr/local/nagios/bin" do
  to "/u/nagios/current/bin"
end

# using the node object inside this block fails, so we assign for now
userlist = node[:nagios][:users]

# TODO: use an htpasswd template and already-encryped passwords
# add_htpasswd_users "/etc/nagios3/htpasswd.users" do
#   users userlist
# end

nodes = []
search(:node, "*", %w(ipaddress hostname)) {|n| nodes << n } unless Chef::Config[:solo]

runit_service "nagios3"

nagios_conf "nagios" do
  config_subdir false
end

directory "#{node[:nagios][:root]}/dist" do
  owner "nagios"
  group "nagios"
  mode 0755
end

%w(templates contacts commands).each do |dir|
  directory "#{node[:nagios][:root]}/conf.d/#{dir}" do
    owner "nagios"
    group "nagios"
    mode 0755
  end
end

execute "archive default nagios object definitions" do
  command "mv #{node[:nagios][:root]}/conf.d/*_nagios*.cfg #{node[:nagios][:root]}/dist"
  not_if { Dir.glob(node[:nagios][:root] + "/conf.d/*_nagios*.cfg").empty? }
end

remote_directory node[:nagios][:notifiers_dir] do
  source "notifiers"
  files_backup 5
  files_owner "nagios"
  files_group "nagios"
  files_mode 0755
  owner "nagios"
  group "nagios"
  mode 0755
end

nagios_conf "hostgroups" do
  variables({:roles => []})
end

nagios_conf "hosts" do
  variables({:hosts => nodes})
end

nagios_template "local-service" do
  template_type "service"
  max_check_attempts      4
  normal_check_interval   300
  retry_check_interval    60
end

nagios_template "frequent-service" do
  template_type "service"
	use "default-service"
	max_check_attempts    3
  normal_check_interval 5
  retry_check_interval  20
end

nagios_template "frequent-service-with-sms" do
  template_type "service"
	use "frequent-service"
  notification_interval 0
  notification_options "u,c,r"
  contact_groups "admins, sysadmin-sms"
end

nagios_conf "templates"
nagios_conf "commands"
nagios_conf "contacts"
nagios_conf "timeperiods"
nagios_conf "services"

template "/etc/nagios3/apache2.conf" do
  source "apache2.conf.erb"
end

apache_site "nagios" do
  config_path "/etc/nagios3/apache2.conf"
end

runit_service "nagios-bot"