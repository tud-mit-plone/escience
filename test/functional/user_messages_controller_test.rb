require 'test_helper'

class UserMessagesControllerTest < ActionController::TestCase
  fixtures :users

  def setup
    @request.env['HTTP_REFERER'] = 'http://foo.bar'

    # track all changes during the test to rollback
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end

  def teardown
    # rollback any changes during the test
    DatabaseCleaner.clean
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:user_messages)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create user_message" do
    assert_difference('UserMessage.count') do
      post :create, :user_message => { }
    end

    assert_redirected_to user_message_path(assigns(:user_message))
  end

  test "should show user_message" do
    get :show, :id => user_messages(:one).to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => user_messages(:one).to_param
    assert_response :success
  end

  test "should update user_message" do
    put :update, :id => user_messages(:one).to_param, :user_message => { }
    assert_redirected_to user_message_path(assigns(:user_message))
  end

  test "should destroy user_message" do
    assert_difference('UserMessage.count', -1) do
      delete :destroy, :id => user_messages(:one).to_param
    end

    assert_redirected_to user_messages_path
  end

  test "receiver gets email notification after saving usermessage" do
    from_user = users(:users_002)
    to_user = users(:users_003)
    to_user.mail_notification = 'all'
    message = create_user_message_stub(from_user, to_user)

    Mailer.deliveries.clear
    assert_difference 'Mailer.deliveries.count' do
      message.save
    end
    email = Mailer.deliveries.last
    receivers = email.to + email.cc + email.bcc
    assert receivers.include?(to_user.mail), "to_user receives email"
    # test text and html body contains message (ignore case)
    assert get_plain_text(email).downcase.include?(message.body.downcase)
    assert get_html_text(email).downcase.include?(message.body.downcase)
  end

  test "history of single usermessage includes it self if author is logged in" do
    author = users(:users_002)
    receiver = users(:users_003)
    # login author is neccessary, because get_history should only list UserMessages
    # where author = current user
    User.current = author
    single_message = create_user_message_stub(author, receiver, nil)
    single_message.save

    history = single_message.get_history
    assert_not_nil history
    assert history.include?(single_message)
    assert_equal 1, history.count
  end

  test "history includes all parents if author is logged in" do
    author = users(:users_002)
    receiver = users(:users_003)
    # login author is neccessary, because get_history should only list UserMessages
    # where author = current user
    User.current = author

    parent_1 = create_user_message_stub(author, receiver, nil)
    parent_2 = create_user_message_stub(author, receiver, parent_1)
    parent_3 = create_user_message_stub(author, receiver, parent_2)
    message = create_user_message_stub(author, receiver, parent_3)
    parent_1.save
    parent_2.save
    parent_3.save
    message.save

    history = message.get_history
    assert_not_nil history
    assert history.include?(message)
    assert history.include?(parent_3)
    assert history.include?(parent_2)
    assert history.include?(parent_1)
    assert_equal 4, history.count
  end

  test "history includes all parents where author is current user" do
    author_1 = users(:users_002)
    author_2 = users(:users_003)
    receiver = users(:users_004)
    # login author_1
    User.current = author_1

    parent_1 = create_user_message_stub(author_1, receiver, nil)
    parent_2 = create_user_message_stub(author_2, receiver, parent_1)
    parent_3 = create_user_message_stub(author_1, receiver, parent_2)
    message = create_user_message_stub(author_2, receiver, parent_3)
    parent_1.save
    parent_2.save
    parent_3.save
    message.save

    history = message.get_history
    assert_not_nil history
    assert !history.include?(message) # because Current.user isn't the author of message
    assert history.include?(parent_3) # because Current.user is the author of parent_3
    assert !history.include?(parent_2) # because Current.user isn't the author of parent_2
    assert history.include?(parent_1) # because Current.user is the author of parent_1
  end

  test "receiver_list returns nil if no receiver set" do
    from = users(:users_002)
    to = users(:users_003)
    message = create_user_message_stub(from, to)
    assert_nil message.receiver_list
  end

  test "receiver_list returns all receiver" do
    from = users(:users_002)
    to = users(:users_003)
    receiver_1 = users(:users_004)
    receiver_2 = users(:users_005)
    receiver_3 = users(:users_006)
    message = UserMessage.new(
      :author => from,
      :user => to,
      :subject => 'Some Subject',
      :body => 'Some Message',
      :receiver => to,
      :receiver_list => [receiver_1, receiver_2, receiver_3]
    )
    receiver_list = message.receiver_list
    assert_not_nil receiver_list
    assert receiver_list.include?(receiver_1)
    assert receiver_list.include?(receiver_2)
    assert receiver_list.include?(receiver_3)
    assert_equal 3, receiver_list.count
  end

  test "recipients_mail includes receiver and receiver_list" do
    from = users(:users_002)
    to = users(:users_003)
    receiver_1 = users(:users_004)
    receiver_2 = users(:users_005)
    receiver_3 = users(:users_006)
    message = UserMessage.new(
      :author => from,
      :user => to,
      :subject => 'Some Subject',
      :body => 'Some Message',
      :receiver => receiver_1,
      :receiver_list => [receiver_2, receiver_3]
    )
    mails = message.recipients_mail
    assert_not_nil mails
    assert mails.include?(receiver_1.mail)

    # no receiver defined
    message = UserMessage.new(
      :author => from,
      :user => to,
      :subject => 'Some Subject',
      :body => 'Some Message',
      :receiver_list => [receiver_2, receiver_3]
    )
    mails = message.recipients_mail
    assert_not_nil mails
    assert mails.include?(receiver_2.mail)
    assert mails.include?(receiver_3.mail)
  end

  test "origin receivers added to reply message" do
    from = users(:users_002)
    to = users(:users_003)
    receiver_1 = users(:users_004)
    receiver_2 = users(:users_005)

    origin = UserMessage.new(
      :author => from,
      :user => from,
      :subject => 'Some Subject',
      :body => 'Some Message',
      :receiver_list => [receiver_1, receiver_2]
    )
    origin.save!

    @request.session[:user_id] = from.id
    # we're reply to origin
    get :new, :reply => origin.id
    # receivers for the new message
    new_receivers = assigns(:receivers)
    assert new_receivers.include?(receiver_1)
    assert new_receivers.include?(receiver_2)
  end

  test "can't create message if not logged in" do
    to = users(:users_003)
    assert_no_difference 'UserMessage.count' do
      post :create, :user_message => {:receiver => to.id.to_s, :subject => 'Lorem', :body => 'Ipsum'}
    end
  end

  test "empty message will not created" do
    from = users(:users_002)
    to = users(:users_003)
    @request.session[:user_id] = from.id

    # anything is empty
    assert_no_difference 'UserMessage.count' do
      post :create, :user_message => {:receiver => '', :subject => '', :body => ''}
    end
    # subject is empty
    assert_no_difference 'UserMessage.count' do
      post :create, :user_message => {:receiver => from.id.to_s, :subject => '', :body => 'Lorem Ipsum'}
    end
    # body is empty
    assert_no_difference 'UserMessage.count' do
      post :create, :user_message => {:receiver => from.id.to_s, :subject => 'Lorem Ipsum', :body => ''}
    end

    # nil parameters
    assert_no_difference 'UserMessage.count' do
      post :create, :user_message => {}
    end
  end

  test "message for unknown user will not created" do
    from = users(:users_002)
    unknown_id = 99999
    @request.session[:user_id] = from.id
    assert_no_difference 'UserMessage.count' do
      post :create, :user_message => {:receiver => unknown_id.to_s, :subject => 'Lorem', :body => 'Ipsum'}
    end
  end

  test "message exists after creating it" do
    from = users(:users_002)
    to = users(:users_003)
    @request.session[:user_id] = from.id

    # message and copy of it will created
    assert_difference 'UserMessage.count', 2 do
      post :create, :user_message => {:receiver => to.id.to_s, :subject => 'Lorem', :body => 'Ipsum'}
    end
    # newly created usermessage bye create action
    message = assigns(:user_message)
    assert_not_nil message
    assert_equal 'Lorem', message.subject
    assert_equal 'Ipsum', message.body

    # find copy of message
    copy = UserMessage.where(:user_message_parent_id => message.id).first
    assert_not_nil copy
    assert_equal 'Lorem', copy.subject
    assert_equal 'Ipsum', copy.body
  end

  test "copy receiver_list contains all receivers" do
    from = users(:users_002)
    receiver_1 = users(:users_003)
    receiver_2 = users(:users_004)
    @request.session[:user_id] = from.id

    receiver_ids = [receiver_1.id, receiver_2.id]
    post :create, :user_message => {:receiver => receiver_ids, :subject => 'Lorem', :body => 'Ipsum'}
    # newly created usermessage bye create action
    message = assigns(:user_message)
    copy = UserMessage.where(:user_message_parent_id => message.id).first
    assert message.receiver_list.include?(receiver_1)
    assert message.receiver_list.include?(receiver_2)
  end

  test "copy receiver_list is empty when hide_receivers" do
    from = users(:users_002)
    receiver_1 = users(:users_003)
    receiver_2 = users(:users_004)
    @request.session[:user_id] = from.id

    receiver_ids = [receiver_1.id, receiver_2.id]
    post :create, :user_message => {
        :hide_receiver => true,
        :receiver => receiver_ids,
        :subject => 'Lorem',
        :body => 'Ipsum'
      }
    # newly created usermessage bye create action
    message = assigns(:user_message)
    copy = UserMessage.where(:user_message_parent_id => message.id).first
    assert copy.receiver_list.nil? or copy.receiver_list.empty?
  end

  test "reply message status is updated to answered" do
    from = users(:users_002)
    to = users(:users_002)

    origin = create_user_message_stub(from, to)
    sent_state = 3 # message was sent
    origin.state = sent_state
    origin.save

    # 'to' sends answer to 'from'
    @request.session[:user_id] = to.id
    post :create, :reply_mail => origin.id,
      :user_message => {:receiver => from.id.to_s, :subject => 'Lorem', :body => 'Ipsum'}

    origin = origin.reload
    answered_state = 4 # message was answered
    assert_equal answered_state, origin.state
  end

  test "messages history contains self" do
    from = users(:users_002)
    to = users(:users_003)
    message = create_user_message_stub(from, to)
    message.save
    begin
      @request.session[:user_id] = from.id
      # no route defined for action history_messages
      # we have to define it at manually
      Rails.application.routes.draw { get 'history_messages' => 'user_messages#history_messages' }
      get :history_messages, :id => message.id, :format => :json
      assert_response :success
      assert assigns(:history).include? message
    ensure
      # restore routes
      Rails.application.reload_routes!
    end
  end

  private
  def create_user_message_stub(from, to, parent=nil)
    UserMessage.new(
      :author => from,
      :user => from,
      :subject => 'Some Subject',
      :body => 'Some Message',
      :receiver => to,
      :parent => parent
    )
  end

  def get_plain_text(email)
    if email.multipart? then
      if !email.text_part.nil? then
        email.text_part.body.decoded
      else
        nil
      end
    else
      email.body.decoded
    end
  end

  def get_html_text(email)
    if !email.html_part.nil? then
      email.html_part.body.decoded
    else
      nil
    end
  end
end
