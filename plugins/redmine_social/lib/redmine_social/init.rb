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
  UserMessagesController.send(:include, ::RedmineSocialExtends::UserMessagesControllerExtension)

  require_dependency 'project'

  require File.join(File.dirname(__FILE__),'patch_project' )
  Project.send(:include, ::RedmineSocialExtends::ProjectsExtension)
  ProjectsHelper.send(:include, ::RedmineSocialExtends::ProjectsHelperExtension)
  require File.join(File.dirname(__FILE__),'patch_projects_controller' )
  ProjectsController.send(:include, ::RedmineSocialExtends::ProjectsControllerExtension)
  
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
  
  require_dependency 'setting'
  require File.join(File.dirname(__FILE__),'patch_setting' )
  SettingsHelper.send(:include, ::RedmineSocialExtends::SettingsHelperExtension)
  
  require File.join(File.dirname(__FILE__),'patch_application_controller' )
  ApplicationController.send(:include, ::RedmineSocialExtends::ApplicationControllerExtension)

  require File.join(File.dirname(__FILE__),'patch_account_controller' )
  AccountController.send(:include, ::RedmineSocialExtends::AccountControllerExtension)

end
require File.join(File.dirname(__FILE__),'patch_pagination')