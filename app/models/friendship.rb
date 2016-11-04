class Friendship < ActiveRecord::Base
  @@daily_request_limit = 12
  cattr_accessor :daily_request_limit

  belongs_to :user
  belongs_to :friend, :class_name => "User", :foreign_key => "friend_id"   
  has_enumerated :friendship_status, :class_name => 'FriendshipStatus', :foreign_key => 'friendship_status_id'

  validates_presence_of   :friendship_status
  validates_presence_of   :user
  validates_presence_of   :friend
  validates_uniqueness_of :friend_id, :scope => :user_id
  validate :cannot_request_if_daily_limit_reached
  validate :both_users_cant_be_initiators
  validates_each :user_id do |record, attr, value|
    record.errors.add attr, 'can not be same as friend' if record.user_id.eql?(record.friend_id)
  end
  
  # named scopes
  scope :accepted, lambda {
    {
      :joins => ',users',
      :conditions => ["friendship_status_id = ? AND friend_id = users.id", FriendshipStatus[:accepted].id],
      :order => 'users.lastname ASC'
    }
  }
  
  def cannot_request_if_daily_limit_reached  
    if new_record? && initiator && user.has_reached_daily_friend_request_limit?
      errors.add(:base, "Sorry, you'll have to wait a little while before requesting any more friendships.") 
    end
  end  
    
  before_validation(:on => :create){:set_pending}
  after_save :notify_requester, :if => Proc.new{|fr| fr.accepted? && fr.initiator }

  attr_protected :friendship_status_id
  
  def reverse
    Friendship.where(user_id: friend_id, friend_id: user_id).first
  end

  def denied?
    friendship_status.eql?(FriendshipStatus[:denied])
  end
  
  def pending?
    friendship_status.eql?(FriendshipStatus[:pending])
  end
  
  def accepted?
    friendship_status.eql?(FriendshipStatus[:accepted])
  end
  
  def self.friends?(user, friend)
    Friendship.where(user_id: user.id, friend_id: friend.id, friendship_status_id: FriendshipStatus[:accepted].id).any?
    # find(:conditions => ["user_id = ? AND friend_id = ? AND friendship_status_id = ?", user.id, friend.id, FriendshipStatus[:accepted].id ]).first
  end
  
  def notify_requester
    #UserNotifier.friendship_accepted(self).deliver
  end
    
  private
  def set_pending
    friendship_status_id = FriendshipStatus[:pending].id
  end

  def both_users_cant_be_initiators
    if initiator && Friendship.where(user_id: friend.id, friend_id: user.id, initiator: true).any?
      errors.add(:initiator, "corresponding friendships can't be both initiators")
    end
  end
end
