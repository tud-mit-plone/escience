module RedmineSocialExtends
  module ProjectsControllerExtension
    module ClassMethods
    end
    module InstanceMethods
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
      receiver.class_eval do
        before_filter :no_private_project, :only => [:show]

        private 

        def no_private_project
          if @project.is_private_project? 
            return render_403 
          else 
            return true 
          end
        end
      end
    end
  end
end