require File.expand_path('../../../../../test/test_helper', __FILE__)

class UserMessagesExtensionTest < ActiveSupport::TestCase
  fixtures :users
  
  def setup
    # track all changes during the test to rollback
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end
  
  def teardown
    # rollback any changes during the test
    DatabaseCleaner.clean
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
    mail = Mailer.deliveries.last
    receivers = mail.to + mail.cc + mail.bcc
    assert receivers.include?(to_user.mail), "to_user receives email"
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
  
  def get_plain_text(mail)
    if mail.multipart? then
      if mail.text_part? then
        message.text_part.body.decoded 
      else
        nil
      end
    else
      message.body.decoded
    end
  end
  
  def get_html_text(mail)
    if message.html_part? then
      message.html_part.body.decoded
    else
      nil
    end
  end
end