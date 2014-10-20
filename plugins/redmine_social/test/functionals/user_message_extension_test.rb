require File.expand_path('../../../../../test/test_helper', __FILE__)

class UserMessageExtensionTest < ActiveSupport::TestCase
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
  
  private
  def create_user_message_stub(from, to)
    UserMessage.new(
      :author => from,
      :user => from,
      :subject => 'Some Subject',
      :body => 'Some Message',
      :receiver => to
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