module RedmineSocialExtends
    module ProjectsExtension
      module ClassMethods
      end
      
      module InstanceMethods
      end
      
      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          acts_as_invitable

          has_one :exclusive_user, :class_name => 'User', :foreign_key => 'private_project_id'
        end
      end
    end
  end