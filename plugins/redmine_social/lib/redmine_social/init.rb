Rails.configuration.to_prepare do
  require_dependency 'user'
  require_dependency 'appointment'
  require File.join(File.dirname(__FILE__),'patch_redmine_classes' )
  User.send(:include, ::RedmineSocialExtends::UserExtension)
  UsersController.send(:include, ::RedmineSocialExtends::UsersController)
  require File.join(File.dirname(__FILE__),'patch_appointment' )
  AppointmentsController.send(:include, ::RedmineSocialExtends::AppointmentsControllerExtension)
end