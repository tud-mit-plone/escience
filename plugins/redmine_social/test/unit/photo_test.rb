require File.expand_path('../../../../../test/test_helper', __FILE__)

class PhotoTest < ActiveSupport::TestCase
  fixtures :users, :attachments
  #ActiveSupport::TestCase.fixture_path = File.expand_path("/../fixtures", __FILE__) 

  ActiveRecord::Fixtures.create_fixtures(File.dirname(__FILE__) + '/../fixtures/', 
                            [:photos])
  
  def setup
    # track all changes during the test to rollback
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end
  
  def teardown
    # rollback any changes during the test
    DatabaseCleaner.clean
  end

  test "photo must have required fields" do
    photo = Photo.new
    assert !photo.save
    assert !photo.errors[:user].empty?
    assert !photo.errors[:photo].empty?    
  end
  
  test "load photo from File" do
    user = users(:users_002)
    photo = create_photo(user, "101223161450_testfile_2.png", "image/png")
    assert photo.valid?
  end

  test "load photo from fixtures" do
    #photo = photos(:photos_001)
    #assert photo.valid?
  end

  test "previous photo" do
    user = users(:users_002)
    photo1 = create_photo(user, "101223161450_testfile_2.png", "image/png")
    photo2 = create_photo(user, "101123161450_testfile_1.png", "image/png")
    assert_equal photo1, photo2.previous_photo
  end

  private
  def create_photo(user, file, type)
    file = uploaded_test_file(file, type)
    if File.exist?(file)
      photo = Photo.create()
      photo.user = user
      photo.photo = file
      photo.save!
      return photo
    else
      return nil
    end
  end

end