require File.expand_path('../../test_helper', __FILE__)

class GroupInvitationTest < ActiveSupport::TestCase
  fixtures :users, :friendship_statuses
  
  test "group invitation must have required fields" do
    group_invitation = GroupInvitation.new()
    assert !group_invitation.save
    assert !group_invitation.errors[:user_messages].empty?
    assert !group_invitation.errors[:friendship_status_id].empty?
    assert !group_invitation.errors[:group].empty? 
  end
  
  test "group invitation create" do
    from_user = users(:users_002)
    to_user = users(:users_003)
    group_invitation = create_group_invitation(from_user, to_user, "test_group")
        
    assert group_invitation.save
    assert group_invitation.errors[:user_messages].empty?
    assert group_invitation.errors[:friendship_status_id].empty?
    assert group_invitation.errors[:group].empty? 
  end
  
  test "add and get invitation group" do
    assert_equal GroupInvitation.get_invitation_group.length, 1
    
    GroupInvitation.add_invitation_group(Group.new(:lastname => "test1"))
    GroupInvitation.add_invitation_group(Group.new(:lastname => "test2"))
    
    assert_equal GroupInvitation.get_invitation_group.length, 3
    assert_equal GroupInvitation.get_invitation_group[1].to_s, "test1"
    assert_equal GroupInvitation.get_invitation_group[2].to_s, "test2"
  end
  
  test "group invitation can't create if less than 2 users involved" do
    from_user = users(:users_002)
    to_user = users(:users_003)
    group_invitation = GroupInvitation.new()
    
    sender_u_msg = create_user_message(from_user, to_user)
    sender_u_msg.save
    group_invitation.user_messages << sender_u_msg
    
    group_invitation.friendship_status_id = FriendshipStatus.where(:name => "pending").first.id
    
    group_invitation.group = Group.new(:lastname => "test")

    assert group_invitation.user_messages.length < 2     
    assert !group_invitation.valid?
    assert !group_invitation.save
  end
  
  test "friendship status" do
    from_user = users(:users_002)
    to_user = users(:users_003)
    group_invitation = create_group_invitation(from_user, to_user, "test_group")

    assert_equal group_invitation.answer, FriendshipStatus[:pending].id
    
    group_invitation.friendship_status_id = FriendshipStatus.where(:name => "accepted").first.id    
    assert_equal group_invitation.answer, FriendshipStatus[:accepted].id
    
    group_invitation.friendship_status_id = FriendshipStatus.where(:name => "denied").first.id    
    assert_equal group_invitation.answer, FriendshipStatus[:denied].id
  end
  
  
  private
  def create_group_invitation(from, to, group)
    inv = GroupInvitation.new()
    
    sender_u_msg = create_user_message(from, to)
    if sender_u_msg.save 
      receiver_u_msg = sender_u_msg.generate_sent_receiver_copy()
      receiver_u_msg = nil unless receiver_u_msg.save
    else
      sender_u_msg = nil 
    end
    inv.user_messages << sender_u_msg
    inv.user_messages << receiver_u_msg
    
    inv.friendship_status_id = FriendshipStatus.where(:name => "pending").first.id
    
    inv.group = Group.new(:lastname => group)

    return inv
  end
  
  private
  def create_user_message(from, to)
    msg = UserMessage.new({ :body => "Body",
                            :subject => "Subject",
                            :user => from,
                            :author => from,
                            :receiver_id => to,
                            :state => 3})
    return msg
  end
  
  
end