require File.expand_path('../../../../../test/test_helper', __FILE__)

class MailerExtensionTest < ActiveSupport::TestCase

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
  
  test "send user_message" do
    ActionMailer::Base.deliveries.clear
    author = users(:users_002)
    User.current = author
    to_user = users(:users_003)

    assert_difference 'ActionMailer::Base.deliveries.size' do
      user_message = UserMessage.create(:author => author, :user => author,
      :subject => 'test Subject', :body => 'Test Message', :receiver => to_user, :parent => nil)
      
      history = user_message.get_history
      assert_equal 1, history.count
      assert history.include?(user_message)
    end
  end

  test "message id for" do
    author = users(:users_002)
    User.current = author
    to_user = users(:users_003)
    user_message = UserMessage.create(:author => author, :user => author,
      :subject => 'test Subject', :body => 'Test Message', :receiver => to_user, :parent => nil)

    assert_not_nil Mailer.message_id_for(user_message)
  end
end
