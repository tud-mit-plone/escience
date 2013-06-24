Rails.configuration.to_prepare do
  require_dependency 'user'
  
  require File.join(File.dirname(__FILE__),'patch_user' )
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

  require_dependency 'project'

  require File.join(File.dirname(__FILE__),'patch_project' )
  Project.send(:include, ::RedmineSocialExtends::ProjectsExtension)

  require_dependency 'mailer'
  require File.join(File.dirname(__FILE__),'patch_mailer' )
  Mailer.send(:include, ::RedmineSocialExtends::MailerExtension)
  
  require File.join(File.dirname(__FILE__),'patch_my' )
  MyController.send(:include, ::RedmineSocialExtends::MyControllerExtension)

  require_dependency 'attachment'
  require File.join(File.dirname(__FILE__),'patch_attachment' )
  Attachment.send(:include, ::RedmineSocialExtends::AttachmentExtension)
  AttachmentsController.send(:include, ::RedmineSocialExtends::AttachmentsControllerExtension)

  require File.join(File.dirname(__FILE__),'patch_account_controller' )
  AccountController.send(:include, ::RedmineSocialExtends::AccountControllerExtension)
    
end