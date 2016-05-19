Rails.configuration.to_prepare do
  require File.join(File.dirname(__FILE__),'patch_application_controller' )
  ApplicationController.send(:include, ::ShibbolethLoginExtends::ApplicationControllerExtension)
end
