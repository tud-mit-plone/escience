module RedmineSocialExtends
  module AccountControllerExtension
    module ClassMethods
    end
    module InstanceMethods
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
      receiver.class_eval do
        def password_authentication
          user = User.try_to_login(params[:username], params[:password])

          if user.nil?
            invalid_credentials
          elsif user.new_record?
            onthefly_creation_failed(user, {:login => user.mail, :auth_source_id => user.auth_source_id })
          else
            # Valid user
            user.create_private_project()
            successful_authentication(user)
          end
        end
      end
    end
  end
end