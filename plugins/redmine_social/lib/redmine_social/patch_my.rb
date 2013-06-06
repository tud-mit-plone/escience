module RedmineSocialExtends
  module MyControllerExtension
    module ClassMethods
    end
    
    module InstanceMethods
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
      receiver.class_eval do
        def render_block
          if params['blockname'].nil?
            redirect_to :action => 'index', :user_id => User.current.id
          else
            action = params['blockaction'].nil? ? 'index' : params['blockaction']
            url = {:controller => params['blockname'], :action => params['blockaction'], :user_id => User.current.id}
            redirect_to url.merge!(params.except(:controller, :action,:blockaction, :blockname))
          end
        end
      end
    end
  end
end
