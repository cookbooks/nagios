default.nagios[:plugins_dir] = "/u/nagios/plugins"

default.nagios[:checks][:memory][:critical] = 150
default.nagios[:checks][:memory][:warning] = 250

default.nagios[:checks][:load][:critical] = "30,20,10"
default.nagios[:checks][:load][:warning] = "15,10,7"

default.nagios[:checks][:haproxy_queue][:critical] = "10"
default.nagios[:checks][:haproxy_queue][:warning] = "1"