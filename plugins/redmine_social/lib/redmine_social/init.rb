Rails.configuration.to_prepare do
  require_dependency 'user'
  require File.join(File.dirname(__FILE__),'patch_redmine_classes' )
  User.send(:include, ::RedmineSocialExtends::UserExtension)
  UsersController.send(:include, ::RedmineSocialExtends::UsersController)
end