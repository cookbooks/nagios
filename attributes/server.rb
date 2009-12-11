default.nagios[:root] = "/etc/nagios3"
default.nagios[:webroot] = "/usr/share/nagios3/htdocs"
default.nagios[:bin_path] = "/usr/sbin/nagios3"
default.nagios[:config_path] = "/etc/nagios3/nagios.cfg"
default.nagios[:config_subdir] = "conf.d"
default.nagios[:users]["nagiosadmin"] = "12345678"
default.nagios[:notifications_enabled] = 1
default.nagios[:check_external_commands] = true
default.nagios[:default_contact_groups] = %w(admins)

# This setting is effectively sets the minimum interval (in seconds) nagios can handle.
# Other interval settings provided in seconds will calculate their actual from this value, since nagios works in 'time units' rather than allowing definitions everywhere in seconds

default.nagios[:templates] = Mash.new # required for the nagios_template definition

default.nagios[:interval_length] = 1

default.nagios[:default_host][:check_interval] = 15
default.nagios[:default_host][:retry_interval] = 15
default.nagios[:default_host][:notification_interval] = 300
default.nagios[:default_host][:max_check_attempts] = 1

default.nagios[:default_service][:check_interval] = 60
default.nagios[:default_service][:retry_interval] = 15
default.nagios[:default_service][:notification_interval] = 1200
default.nagios[:default_service][:max_check_attempts] = 3

default.nagios[:notifiers_dir] = "/var/lib/nagios3/notifiers"

default.nagios[:bot_path] = "#{nagios[:notifiers_dir]}/jabber_bot"