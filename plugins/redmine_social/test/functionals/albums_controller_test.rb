require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')

class AlbumsControllerTest < ActionController::TestCase
	self.fixture_path = "#{Rails.root}/plugins/redmine_social/test/fixtures/"

	fixtures :users, :albums, :photos

	def setup
    # track all changes during the test to rollback
    DatabaseCleaner.strategy = :truncation
  	DatabaseCleaner.start
  	fix_fixture_path
  end
  
  def teardown
   	# rollback any changes during the test
   	DatabaseCleaner.clean
  end

 	test "filter require login" do
    album = albums(:albums_001)
    get :show, id: album.id
    #assert_equal @controller.l(:please_log_in), flash[:error]
    assert_response :redirect
    assert_redirected_to "/?back_url=http%3A%2F%2Ftest.host%2Falbums%2F1"
  end

	test "create_album" do
		# user = users(:users_002)
		# album = albums(:albums_001)
		# assert_equal 'Test-Album-01', album.title, 'Wrong title'
		# #assert album.photos.size == 2
		# photo = Photo.create(user: user, album: album)

		# assert_equal 2, album.photos.size, "False size"
	end


	private
  	# Because a bug, a overriden fixture_path method get not called for files,
  	# so we have to set the variable manually.
  	# https://github.com/rspec/rspec-rails/issues/252#issuecomment-1438267
  	def fix_fixture_path
    	ActiveSupport::TestCase.class_eval do
      	include ActiveRecord::TestFixtures
      	self.fixture_path = "#{Rails.root}/plugins/redmine_social/test/fixtures/"
    end
  	end

    def create_photo(user, file, type)
    file = uploaded_test_file(file, type)
    if File.exist?(file)
      photo = Photo.create()
      photo.user_id = user.id
      photo.photo = file
      photo.save!
      return photo
    else
      return nil
    end
  end

end
