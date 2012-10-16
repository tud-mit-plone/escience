class UserContact < ActiveRecord::Base
  belongs_to :user
  belongs_to :contact_member, :class_name => 'User', :foreign_key => 'contact_member_id'
  # attr_accessible :title, :body
end
