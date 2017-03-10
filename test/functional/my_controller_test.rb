# Redmine - project management software
# Copyright (C) 2006-2012  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require File.expand_path('../../test_helper', __FILE__)
require 'my_controller'

# Re-raise errors caught by the controller.
class MyController; def rescue_action(e) raise e end; end

class MyControllerTest < ActionController::TestCase
  fixtures :users, :user_preferences, :roles, :projects, :members, :member_roles,
  :issues, :issue_statuses, :trackers, :enumerations, :custom_fields, :auth_sources

  def setup
    @controller = MyController.new
    @request    = ActionController::TestRequest.new
    @request.session[:user_id] = 2
    @response   = ActionController::TestResponse.new
    @request.env['HTTP_REFERER'] = 'http://foo.bar'
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'page'
  end

  def test_page
    get :page
    assert_response :success
    assert_template 'page'
  end

  def test_page_with_timelog_block
    preferences = User.find(2).pref
    preferences[:my_page_layout] = {'top' => ['timelog']}
    preferences.save!
    TimeEntry.create!(:user => User.find(2), :spent_on => Date.yesterday, :issue_id => 1, :hours => 2.5, :activity_id => 10)

    get :page
    assert_response :success
    assert_select 'tr.time-entry' do
      assert_select 'td.subject a[href=/issues/1]'
      assert_select 'td.hours', :text => '2.50'
    end
  end

  def test_my_account_should_show_editable_custom_fields
    get :account
    assert_response :success
    assert_template 'account'
    assert_equal User.find(2), assigns(:user)

    assert_tag :input, :attributes => { :name => 'user[custom_field_values][4]'}
  end

  def test_my_account_should_not_show_non_editable_custom_fields
    UserCustomField.find(4).update_attribute :editable, false

    get :account
    assert_response :success
    assert_template 'account'
    assert_equal User.find(2), assigns(:user)

    assert_no_tag :input, :attributes => { :name => 'user[custom_field_values][4]'}
  end

  def test_update_account
    post :account,
      :user => {
        :firstname => "Joe",
        :login => "root",
        :admin => 1,
        :group_ids => ['10'],
        :custom_field_values => {"4" => "0100562500"}
      }

    assert_redirected_to '/my/account'
    user = User.find(2)
    assert_equal user, assigns(:user)
    assert_equal "Joe", user.firstname
    assert_equal "jsmith", user.login
    assert_equal "0100562500", user.custom_value_for(4).value
    # ignored
    assert !user.admin?

    # FIXME merge both versions
    assert user.groups.empty?
    user = users(:users_002)

    # ensure user has accepted Terms & Privacy
    #user.confirm = true

    user_hash = user.attributes
    user_hash[:firstname] = 'Joe'

    post :account,
         :user => user_hash,
         :pref => {:hide_mail => false},
         :my_interest => 'Soccer, Computer',
         :my_skill => 'Java, Testing',
         :enabled_module_names => ['time_tracking']

    assert_redirected_to my_account_path(:sub => 'my_account')

    #reload user to refresh the user attributes
    user.reload

    assert_equal user, assigns(:user)
    assert_equal "Joe", user.firstname
    assert_equal "Soccer", user.interest_list[0]
    assert_equal "Computer", user.interest_list[1]
    assert_equal "Java", user.skill_list[0]
    assert_equal "Testing", user.skill_list[1]
  end

  def test_my_account_should_show_destroy_link
    get :account
    assert_select 'a[href=/my/account/destroy]'
  end

  def test_get_destroy_should_display_the_destroy_confirmation
    get :destroy
    assert_response :success
    assert_template 'destroy'
    assert_select 'form[action=/my/account/destroy]' do
      assert_select 'input[name=confirm]'
    end
  end

  def test_post_destroy_without_confirmation_should_not_destroy_account
    assert_no_difference 'User.count' do
      post :destroy
    end
    assert_response :success
    assert_template 'destroy'
  end

  def test_post_destroy_without_confirmation_should_destroy_account
    assert_difference 'User.count', -1 do
      post :destroy, :confirm => '1'
    end
    assert_redirected_to '/'
    assert_match /deleted/i, flash[:notice]
  end

  def test_post_destroy_with_unsubscribe_not_allowed_should_not_destroy_account
    User.any_instance.stubs(:own_account_deletable?).returns(false)

    assert_no_difference 'User.count' do
      post :destroy, :confirm => '1'
    end
    assert_redirected_to '/my/account'
  end

  def test_change_password
    get :password
    assert_response :success
    assert_template 'password'

    # non matching password confirmation
    post :password, :password => 'jsmith',
                    :new_password => 'hello',
                    :new_password_confirmation => 'hello2'
    assert_response :success
    assert_template 'password'
    assert_error_tag :content => /Password doesn&#x27;t match confirmation/

    # wrong password
    post :password, :password => 'wrongpassword',
                    :new_password => 'hello',
                    :new_password_confirmation => 'hello'
    assert_response :success
    assert_template 'password'
    assert_equal 'Wrong password', flash[:error]

    # good password
    post :password, :password => 'jsmith',
                    :new_password => 'hello',
                    :new_password_confirmation => 'hello'
    assert_redirected_to '/my/account'
    assert User.try_to_login('jsmith', 'hello')
  end

  def test_change_password_should_redirect_if_user_cannot_change_its_password
    User.find(2).update_attribute(:auth_source_id, 1)

    get :password
    assert_not_nil flash[:error]
    assert_redirected_to '/my/account'
  end

  def test_page_layout
    get :page_layout
    assert_response :success
    assert_template 'page_layout'
  end

  def test_add_block
    post :add_block, :block => 'issuesreportedbyme'
    assert_redirected_to '/my/page_layout'
    assert User.find(2).pref[:my_page_layout]['top'].include?('issuesreportedbyme')
  end

  def test_remove_block
    post :remove_block, :block => 'issuesassignedtome'
    assert_redirected_to '/my/page_layout'
    assert !User.find(2).pref[:my_page_layout].values.flatten.include?('issuesassignedtome')
  end

  def test_order_blocks
    xhr :post, :order_blocks, :group => 'left', 'blocks' => ['documents', 'calendar', 'latestnews']
    assert_response :success
    assert_equal ['documents', 'calendar', 'latestnews'], User.find(2).pref[:my_page_layout]['left']
  end

  def test_reset_rss_key_with_existing_key
    @previous_token_value = User.find(2).rss_key # Will generate one if it's missing
    post :reset_rss_key

    assert_not_equal @previous_token_value, User.find(2).rss_key
    assert User.find(2).rss_token
    assert_match /reset/, flash[:notice]
    assert_redirected_to '/my/account'
  end

  def test_reset_rss_key_without_existing_key
    assert_nil User.find(2).rss_token
    post :reset_rss_key

    assert User.find(2).rss_token
    assert_match /reset/, flash[:notice]
    assert_redirected_to '/my/account'
  end

  def test_reset_api_key_with_existing_key
    @previous_token_value = User.find(2).api_key # Will generate one if it's missing
    post :reset_api_key

    assert_not_equal @previous_token_value, User.find(2).api_key
    assert User.find(2).api_token
    assert_match /reset/, flash[:notice]
    assert_redirected_to '/my/account'
  end

  def test_reset_api_key_without_existing_key
    assert_nil User.find(2).api_token
    post :reset_api_key

    assert User.find(2).api_token
    assert_match /reset/, flash[:notice]
    assert_redirected_to '/my/account'
  end

  test "interest search" do
    word_syllable = "admini"
    get :interest_search, :q => word_syllable, :format => :json
    assert_response :success
    interests = json_response
    tag_names = get_tag_names(interests)
    assert tag_names.include?('administration')
  end

  test "skill search" do
    word_syllable = "progra"
    get :skill_search, :q => word_syllable, :format => :json
    assert_response :success
    skills = json_response
    tag_names = get_tag_names(skills)
    assert tag_names.include?('programming')
  end

  test "prepare tag params" do
    my_controller_dummy = MyController.new
    example_tag_string = 'Soccer, Computer, TV'
    prepared_tag_list = my_controller_dummy.prepare_tag_params(example_tag_string)

    assert_equal prepared_tag_list.count, 3
    assert_equal "Soccer", prepared_tag_list[0]
    assert_equal "Computer", prepared_tag_list[1]
    assert_equal "TV", prepared_tag_list[2]
  end

  # test "redirect to index if render block has no blockname attribut" do
    # uid = @user.id
    # get :render_block, :blockname => nil
    # assert_redirected_to '/my?user_id='+uid.to_s
  # end

  private

  def json_response
    ActiveSupport::JSON.decode @response.body
  end

  def get_tag_names(tags)
    tags.collect {|entry| entry["tag"]["name"]}
  end

end
