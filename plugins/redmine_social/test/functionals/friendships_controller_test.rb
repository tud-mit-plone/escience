require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')

class FriendshipsControllerTest < ActionController::TestCase

	fixtures :users

	ActiveRecord::Fixtures.create_fixtures(File.dirname(__FILE__) + '/../fixtures/', 
                            [:friendships])

	def setup
		@controller = FriendshipsController.new
		@request    = ActionController::TestRequest.new
		@user = User.find_by_id(2)
		@request.session[:user_id] = @user.id
    	User.current = @user
    end

	def test_index
		puts "user id: #{@user.id}"
		get :index
		assert_response :success
	end

	def test_add_new_friend
		friend_count = @user.accepted_friendships.count
		users_friend = User.find_by_id(4)
		@request.session[:friend_id] = users_friend.id
		@controller.create
		assert_equal friend_count + 1, @user.accepted_friendships.count, "False size"
	end

end