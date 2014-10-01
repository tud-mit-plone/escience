require File.expand_path(File.dirname(__FILE__) + '/../../../../test/test_helper')

class AlbumControllerTest < ActionController::TestCase
	#fixtures aus dem redmine-test-ordner laden
	fixtures :users
	#fixtures aus dem plugin-test-ordner laden
	ActiveRecord::Fixtures.create_fixtures(File.dirname(__FILE__) + '/../fixtures/', 
                            [:albums])

	test "create_album" do
		user = User.find(2)
		album = Album.find_by_id(1)
		assert_equal 'Test-Album-01', album.title, 'Wrong title'
		#assert album.photos.size == 2
		photo = Photo.create(user: user, album: album)

		assert_equal 3, album.photos.size, "False size"
	end

end
