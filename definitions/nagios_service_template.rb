define :nagios_template, :template_type => "service" do
  node[:nagios][:templates]["#{params[:name]}-#{params[:template_type]}"] = params
end