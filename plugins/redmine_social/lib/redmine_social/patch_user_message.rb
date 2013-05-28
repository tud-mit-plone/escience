module RedmineSocialExtends
    module UserMessagesExtension
      module ClassMethods
      end
      
      module InstanceMethods
        def generate_sent_receiver_copy(receiver_id = self.receiver_id)
          return UserMessage.new({ :body => self.body,
                                                                 :subject => self.subject,
                                                                 :user_id => self.user.id,
                                                                 :author => receiver_id,
                                                                 :receiver_id => receiver_id,
                                                                 :state => 1,
                                                                 :directory => UserMessage.received_directory, 
                                                                 :parent => self})
        end
        def recipients_mail
          return [self.receiver_id || self.receiver_list].flatten.map{|m| User.find(m)}.collect(&:mail)
        end
      end

      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          has_and_belongs_to_many :group_invitations,
                        :join_table => :invitation_user_messages,
                        :foreign_key => :user_message_id,
                        :association_foreign_key => :group_invitation_id
          #it's expensive to search for all children, but atm it's not necessary
          belongs_to :parent, :class_name =>'UserMessage', :foreign_key => :user_message_parent_id
        end
      end
    end
  end