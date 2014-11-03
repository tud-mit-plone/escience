require File.expand_path('../../../../../test/test_helper', __FILE__)

class PhotoTest < ActiveSupport::TestCase
  self.fixture_path = "#{Rails.root}/plugins/redmine_social/test/fixtures/"

  fixtures :users, :attachments, :photos
  
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
    user = users(:users_002)
    assert_equal 2, user.photos.count
    #photo = photos(:photos_001)
    #assert photo.valid?
  end

  test "previous photo" do
    user = users(:users_002)
    photo1 = create_photo(user, "101223161450_testfile_2.png", "image/png")
    photo2 = create_photo(user, "101123161450_testfile_1.png", "image/png")
    assert_equal photo1, photo2.previous_photo
  end

  test "next in album" do
    user = users(:users_002)
    album = Album.create(
      :title => "Album-Title 1",
      )
    album.user = user
    album.save!
    photo1 = create_photo(user, "101223161450_testfile_2.png", "image/png")
    assert_equal nil, photo1.next_in_album
    photo1.album = album
    photo1.save!
    photo2 = create_photo(user, "101123161450_testfile_1.png", "image/png")
    photo2.album = album
    photo2.save!
    assert_equal photo2, photo1.next_in_album
  end

  test "file exists" do
    user = users(:users_002)
    photo = create_photo(user, "101223161450_testfile_2.png", "image/png")
    puts Photo.file_exists?(photo)
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
      photo.user = user
      photo.photo = file
      photo.save!
      return photo
    else
      return nil
    end
  end

end