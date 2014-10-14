require File.expand_path('../../../../../test/test_helper', __FILE__)

class PhotoTest < ActiveSupport::TestCase
  fixtures :users, :attachments

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
    file = uploaded_test_file("101223161450_testfile_2.png", "image/png")
    photo = Photo.new
    photo.user = user
    photo.photo = file
    assert photo.save!
    assert photo.valid?
  end

  test "load photo from fixtures" do
    photo = photos(:photos_001)
    assert photo.valid?
  end
end