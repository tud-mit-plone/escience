Rails.configuration.to_prepare do
  require_dependency 'user'
  
  require File.join(File.dirname(__FILE__),'patch_redmine_classes' )
  User.send(:include, ::RedmineSocialExtends::UserExtension)
  UsersController.send(:include, ::RedmineSocialExtends::UsersController)
  
  require_dependency 'appointment'

  require File.join(File.dirname(__FILE__),'patch_appointment' )
  AppointmentsController.send(:include, ::RedmineSocialExtends::AppointmentsControllerExtension)

  require_dependency 'comment'

  require File.join(File.dirname(__FILE__),'patch_comment' )
  CommentsController.send(:include, ::RedmineSocialExtends::CommentsControllerExtension)

  require_dependency 'user_message'

  require File.join(File.dirname(__FILE__),'patch_user_message' )
  UserMessage.send(:include, ::RedmineSocialExtends::UserMessagesExtension)
end