Rails.configuration.to_prepare do
  require File.join(File.dirname(__FILE__),'patch_application_controller' )
  ApplicationController.send(:include, ::ShibbolethLoginExtends::ApplicationControllerExtension)

  require File.join(File.dirname(__FILE__),'patch_account_controller' )
  AccountController.send(:include, ::ShibbolethLoginExtends::AccountControllerExtension)
end
