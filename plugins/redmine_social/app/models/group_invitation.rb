class GroupInvitation < ActiveRecord::Base
  belongs_to :group, :polymorphic => true
  has_one :friendship_status

  has_and_belongs_to_many :user_messages,
                          :join_table => :invitation_user_messages,
                          :foreign_key => :group_invitation_id,
                          :association_foreign_key => :user_message_id

  validates_presence_of :user_messages
  validates_presence_of :friendship_status_id
  validates_presence_of :group
  validate :need_two_users 
  serialize :role_ids

  @@invitation_groups = [] 

   def self.add_invitation_group(group)
     @@invitation_groups << group    
   end
   
   def self.get_invitation_group
    @@invitation_groups    
  end
  
  def answer
    return friendship_status_id
  end

  private 

  def need_two_users
    if self.user_messages.length < 2
      errors.add(:base, l(:group_invitation_one_sender_one_receiver_needed))
    end
  end
end