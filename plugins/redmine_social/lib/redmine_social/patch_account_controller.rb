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
        def successful_authentication(user)
          logger.info "Successful authentication for '#{user.login}' from #{request.remote_ip} at #{Time.now.utc}"
          # Valid user
          self.logged_user = user
          begin 
            user.create_private_project()
          rescue => e
            logger.error(e.message)
            logger.error(e.backtrace)
          end
          # generate a key and set cookie if autologin
          if params[:autologin] && Setting.autologin?
            set_autologin_cookie(user)
          end
          call_hook(:controller_account_success_authentication_after, {:user => user })
          if !(Project.find(:first, :conditions => "name = 'eScience'").nil?)
            session[:selected_project] = Project.find(:first, :conditions => "name = 'eScience'")
            redirect_back_or_default :controller => 'my', :action => 'page'
          else
            redirect_back_or_default :controller => 'my', :action => 'page'
          end
        end
      end
    end
  end
end