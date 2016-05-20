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
        after_filter :set_initial_session_scope, :only => [:login]

        def set_initial_session_scope
          session[:current_view_of_eScience] = '0'
        end
      end
    end
  end
end
