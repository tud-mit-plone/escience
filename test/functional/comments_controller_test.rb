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

class CommentsControllerTest < ActionController::TestCase
  fixtures :projects, :users, :roles, :members, :member_roles, :enabled_modules, :news, :comments

  def setup
    User.current = nil
  end

  def test_add_comment
    @request.session[:user_id] = 2
    post :create, :id => 1, :comment => { :comments => 'This is a test comment' }
    assert_redirected_to '/news/1'

    comment = News.find(1).comments.last
    assert_not_nil comment
    assert_equal 'This is a test comment', comment.comments
    assert_equal User.find(2), comment.author
  end

  def test_empty_comment_should_not_be_added
    @request.session[:user_id] = 2
    assert_no_difference 'Comment.count' do
      post :create, :id => 1, :comment => { :comments => '' }
      assert_response :redirect
      assert_redirected_to '/news/1'
    end
  end

  def test_create_should_be_denied_if_news_is_not_commentable
    News.any_instance.stubs(:commentable?).returns(false)
    @request.session[:user_id] = 2
    assert_no_difference 'Comment.count' do
      post :create, :id => 1, :comment => { :comments => 'This is a test comment' }
      assert_response 403
    end
  end

  def test_destroy_comment
    comments_count = News.find(1).comments.size
    @request.session[:user_id] = 2
    delete :destroy, :id => 1, :comment_id => 2
    assert_redirected_to '/news/1'
    assert_nil Comment.find_by_id(2)
    assert_equal comments_count - 1, News.find(1).comments.size
  end

  test "create comment for news" do
    user_1 = users(:users_002)
    @request.session[:user_id] = user_1.id

    news = news(:news_003)

    # ensure no comments exist for news
    Comment.destroy_all

    assert_difference 'news.comments.count' do
      post :create_general_comment, :news_id => news.id, :id => news.id, :comment => { :comments => 'This is a test comment for news' }
    end
    assert_redirected_to news_path(news)

    comment = news.comments.last
    assert_not_nil comment
    assert_equal 'This is a test comment for news', comment.comments
    assert_equal user_1, comment.author
  end

  test "create comment for photo" do
    user_1 = users(:users_002)
    @request.session[:user_id] = user_1.id

    #photo = photos(:photos_001)
    photo = Photo.find_by_id(1)

    # ensure no comments exist for news
    Comment.destroy_all

    assert_difference 'photo.comments.count' do
      post :create_general_comment, :photo_id => photo.id, :id => photo.id, :comment => { :comments => 'This is a test comment for photo' }
    end
    assert_redirected_to photo_path(photo)

    comment = photo.comments.last
    assert_not_nil comment
    assert_equal 'This is a test comment for photo', comment.comments
    assert_equal user_1, comment.author
  end

  test "empty comment should not be added for news" do
    user_1 = users(:users_002)
    @request.session[:user_id] = user_1.id

    news = news(:news_003)

    assert_no_difference 'Comment.count' do
      post :create_general_comment, :news_id => news.id, :id => news.id, :comment => { :comments => '' }
      assert_response :redirect
      assert_redirected_to news_path(news)
    end
  end

  test "empty comment should not be added for photo" do
    user_1 = users(:users_002)
    @request.session[:user_id] = user_1.id

    #photo = photos(:photos_001)
    photo = Photo.find_by_id(1)

    assert_no_difference 'Comment.count' do
      post :create_general_comment, :photo_id => photo.id, :id => photo.id, :comment => { :comments => '' }
      assert_response :redirect
      assert_redirected_to photo_path(photo)
    end
  end
end
