Dir::foreach(File.join(File.dirname(__FILE__), 'lib')) do |file|
  next if /\.{1,2}/ =~ file
  next unless File.exist?(File.join(File.dirname(__FILE__), 'lib',file,"init.rb"))
  p "shibboleth_login requires #{File.join(File.dirname(__FILE__), 'lib',file,"init.rb")}"
  require File.join(File.dirname(__FILE__), 'lib',file,"init.rb")
end

Redmine::Plugin.register :shibboleth_login do
  name 'Shibboleth Login plugin'
  author 'Sebastian Gottfried'
  description 'Integrates authentication via a Shibboleth SP'
  version '0.0.1'
  settings(:default => {
    "enabled" => false,
    "shibboleth_path" => '/Shibboleth.sso'
  }, :partial => 'settings/shibboleth_login_settings')
end
