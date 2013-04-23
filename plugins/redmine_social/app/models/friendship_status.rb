class FriendshipStatus < ActiveRecord::Base
  unloadable
  acts_as_enumerated 
  attr_accessible :name
end
