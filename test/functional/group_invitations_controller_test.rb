require File.expand_path('../../test_helper', __FILE__)

class GroupInvitationsControllerTest < ActionController::TestCase
  fixtures :users, :projects
  
  def setup
    # track all changes during the test to rollback
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end
  
  def teardown
    # rollback any changes during the test
    DatabaseCleaner.clean
  end
  
  test "unable to create group invitations if user not logged in" do
    admin = users(:users_001)
    member_1 = users(:users_002)
    member_2 = users(:users_003)
    # this project has no other GroupInvitations
    project = projects(:projects_006)
    
    # roles for the new members
    developer_role = Role.where(:name => 'Entwickler').first
    #leader_role = Role.where(:name => 'Leiter').first
    role_ids = [developer_role.id] #[developer_role.id, leader_role.id]

    # members to invite
    member_ids = [member_1.id, member_2.id]

    membership = {:user_ids => member_ids, :role_ids => role_ids}

    assert_no_difference 'GroupInvitation.count' do
      post :create, :controller_name => 'Project', :id => project.id, :membership => membership
    end
  end
  
  test "group invitations status is pending after request" do
    admin = users(:users_001)
    member_1 = users(:users_002)
    member_2 = users(:users_003)
    # this project has no other GroupInvitations
    project = projects(:projects_006)
    
    # roles for the new members
    developer_role = Role.where(:name => 'Entwickler').first
    #leader_role = Role.where(:name => 'Leiter').first
    role_ids = [developer_role.id] #[developer_role.id, leader_role.id]

    # members to invite
    member_ids = [member_1.id, member_2.id]

    membership = {:user_ids => member_ids, :role_ids => role_ids}
    
    # login admin
    @request.session[:user_id] = admin.id

    Mailer.deliveries.clear
    assert_difference 'GroupInvitation.count', +2 do
      post :create, :controller_name => 'Project', :id => project.id, :membership => membership
    end
    
    emails = Mailer.deliveries
    # member_1 and member_2 got emails
    assert_equal 2, emails.count
    assert emails.any? {|email| email_receivers(email).include? member_1.mail}, "member_1 got email"
    assert emails.any? {|email| email_receivers(email).include? member_2.mail}, "member_2 got email"
    
    member_1_invitation = GroupInvitation.find do |inv|
      (inv.group == project) and (inv.user_messages.any? {|um| um.receiver == member_1})
    end
    member_2_invitation = GroupInvitation.find do |inv|
      (inv.group == project) and (inv.user_messages.any? {|um| um.receiver == member_2})
    end

    pending_status = FriendshipStatus.where(:name => 'pending').first
    assert_equal pending_status.id, member_1_invitation.answer
    assert_equal pending_status.id, member_2_invitation.answer
  end
  
  test "member accepts inviting and gets a member of the group with a special role" do
    admin = users(:users_001)
    member_1 = users(:users_002)
    member_2 = users(:users_003)
    # this project has no other GroupInvitations
    project = projects(:projects_006)
    
    # roles for the new members
    developer_role = Role.where(:name => 'Entwickler').first
    #leader_role = Role.where(:name => 'Leiter').first
    role_ids = [developer_role.id] #[developer_role.id, leader_role.id]

    # members to invite
    member_ids = [member_1.id, member_2.id]

    membership = {:user_ids => member_ids, :role_ids => role_ids}
    
    # login admin
    @request.session[:user_id] = admin.id

    post :create, :controller_name => 'Project', :id => project.id, :membership => membership
       
    member_1_invitation = GroupInvitation.find do |inv|
      (inv.group == project) and (inv.user_messages.any? {|um| um.receiver == member_1})
    end
    
    # login member_1
    @request.session[:user_id] = member_1.id

    # member_1 accepts invitation
    accepted = true # anything != nil
    assert_difference 'project.members.count' do
      post :selection, :true => accepted, :id => member_1_invitation.id
    end
    
    # reload project and invitations
    project = project.reload
    member_1_invitation = member_1_invitation.reload

    accepted_status = FriendshipStatus.where(:name => 'accepted').first
    assert_equal accepted_status.id, member_1_invitation.answer
    
    # member_1 is now member of project and member_2 not
    assert project.members.any? {|m| m.user == member_1}
    assert !project.members.any? {|m| m.user == member_2}

    # member_1 is a developer of the project so he can edit it
    assert member_1.allowed_to?(:edit_project, project)

    # member_1 isn't a leader so he isn't allowed to close the project
    assert !member_1.allowed_to?(:close_project, project)

    # member_2 isn't a member of the project so he isn't allowed to view wiki pages
    assert !member_2.allowed_to?(:view_wiki_pages, project)
  end
  
  test "member denies inviting" do
    admin = users(:users_001)
    member_1 = users(:users_002)
    member_2 = users(:users_003)
    # this project has no other GroupInvitations
    project = projects(:projects_006)
    
    # roles for the new members
    developer_role = Role.where(:name => 'Entwickler').first
    #leader_role = Role.where(:name => 'Leiter').first
    role_ids = [developer_role.id] #[developer_role.id, leader_role.id]

    # members to invite
    member_ids = [member_1.id, member_2.id]

    membership = {:user_ids => member_ids, :role_ids => role_ids}
    
    # login admin
    @request.session[:user_id] = admin.id

    post :create, :controller_name => 'Project', :id => project.id, :membership => membership
        
    member_1_invitation = GroupInvitation.find do |inv|
      (inv.group == project) and (inv.user_messages.any? {|um| um.receiver == member_1})
    end
    
    # login member_1
    @request.session[:user_id] = member_1.id

    # member_1 denies invitation
    accepted = nil
    assert_no_difference 'project.members.count' do
      post :selection, :true => accepted, :id => member_1_invitation.id
    end
    
    # reload project and invitations
    project = project.reload
    member_1_invitation = member_1_invitation.reload

    denied_status = FriendshipStatus.where(:name => 'denied').first
    assert_equal denied_status.id, member_1_invitation.answer
    
    # member_1 isn't a member of the project after deny so he isn't allowed to view wiki pages
    assert !member_1.allowed_to?(:view_wiki_pages, project)
  end
  
    
  private
  def email_receivers(email)
    email.to + email.cc + email.bcc
  end
  
end