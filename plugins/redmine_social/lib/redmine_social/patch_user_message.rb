module RedmineSocialExtends
    module UserMessagesExtension
      module ClassMethods
      end
      
      module InstanceMethods
      end
      
      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          has_and_belongs_to_many :group_invitations,
                        :join_table => :invitation_user_messages,
                        :foreign_key => :user_message_id,
                        :association_foreign_key => :group_invitation_id
        end
      end
    end
  end