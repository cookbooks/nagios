require_recipe "nginx"
require_recipe "fcgiwrap"
include_recipe "users"

package "nagios3"
package "nagios-nrpe-plugin"
package 'spawn-fcgi'

# required for Solr plugin
gem_package "xml-simple"
gem_package "choice"

gem_package "tinder"
gem_package "twilio"
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

htpasswd_file "/etc/nagios3/htpasswd.users" do
  owner "nagios"
  group "www-data"
  mode 0640
end

directory "/var/lib/nagios3" do
  mode 0755
end

directory "/var/lib/nagios3/rw" do
  group "www-data"
  mode 02775
end

link "/bin/mail" do
  to "/usr/bin/mailx"
end

runit_service "nagios3"

sysadmin = search(:credentials, "id:sysadmin").first
campfire = search(:credentials, "id:campfire").first
sysadmin_users = search(:users, "group:admin")

nagios_conf "nagios" do
  config_subdir false
  variables({:sysadmin => sysadmin})
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

nodes = []

search(:node, "*:*") {|n| nodes << n }
devices = search(:devices, "*:*")

nagios_conf "hosts" do
  variables({:hosts => nodes, :devices => devices})
end

nagios_conf "contacts" do
  variables({:sysadmins => sysadmin_users, :campfire => campfire})
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
  contact_groups "sysadmin, sysadmin-sms"
end

nagios_conf "templates"
nagios_conf "commands"
nagios_conf "timeperiods"

nagios_conf "cgi" do
  config_subdir false
end

nagios_conf "services" do
  variables(:service_templates => node[:nagios][:templates][:service])
end

template "/etc/nagios3/nginx.conf" do
  source "nginx.conf.erb"
end

# install the wildcard cert for this domain
ssl_certificate "*.#{node[:public_domain] || node[:domain]}"

link "/usr/share/nagios3/htdocs/stylesheets" do
  to "/etc/nagios3/stylesheets"
end

nginx_site "nagios" do
  config_path "/etc/nagios3/nginx.conf"
end

bot_data = search(:credentials, "id:jabber").first

runit_service "nagios-bot" do
  options :bot_data => bot_data
end