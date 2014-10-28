require File.expand_path('../../../../../test/test_helper', __FILE__)
require File.join(File.dirname(__FILE__), '../fix_image_extractor')

class AttachmentExtensionTest < ActiveSupport::TestCase
  # we need for Attachments some container type, so lets take Issue 
  fixtures :issues
  # we also need an Author for Attachments
  fixtures :users

  def setup
    # track all changes during the test to rollback
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start

    # fixture_file_upload (called by uploaded_test_file) has a bug.
    # It calls fixture_path method on TestCase not on the overriden
    # method. We have to repair the fixture_path manually.
    fix_fixture_path
    
    # every attachment needs a container and a author
    @container = issues(:issues_001)
    @author = users(:users_002)
    
    # storage of rendered images (get removed while teardown)
    @temp_render_storage = Dir.mktmpdir
    
    # Fixes a Bug in Docsplit on Windows
    fix_docsplit_extract_images_for_windows
  end
  
  def teardown
    # rollback any changes during the test
    DatabaseCleaner.clean
    
    # remove temporary render storage
    FileUtils.remove_entry_secure @temp_render_storage if File.exists?(@temp_render_storage)
  end
  
  # Because a bug, a overriden fixture_path method get not called,
  # so we have to set the variable manually.
  # https://github.com/rspec/rspec-rails/issues/252#issuecomment-1438267
  def fix_fixture_path
    ActiveSupport::TestCase.class_eval do
      include ActiveRecord::TestFixtures
      self.fixture_path = "#{Rails.root}/plugins/redmine_social/test/fixtures/"
    end
  end

  test "test rendered thumbnail for pdf has the right size" do
    User.current = users(:users_002)
    
    # An Attachment needs at least one MetaInformation
    meta = MetaInformation.new(
      :meta_information => 'Foo',
      :user => User.current
    )
    meta.save!
    
    attachment = Attachment.new(
      :container => @container,
      :file => uploaded_test_file("lorem_hipsum_2_pager.pdf", "application/pdf"),
      :author => @author,
      :meta_information => [meta]
    )
    attachment.save!

    # Docsplit can create thumbnails for PDFs 
    assert attachment.image_convertable?
    
    # render thumbnail for the first page of the PDF
    size = 100
    output_file = attachment.render_to_image(
      :size => size,
      :pages => 1,
      :input => Attachment.storage_path,
      :output => @temp_render_storage
    )
    
    # load rendered thumbnail image
    assert_file_exists output_file
    thumbnail = Magick::Image::read(output_file).first
    assert_not_nil thumbnail
    width, height = thumbnail.columns, thumbnail.rows
    # either width or height is 100px. the other side should less or equal
    assert_equal size, [width, height].max
  end

  test "supported file types are image_convertable" do
    attachment = Attachment.new
    
    # test supported file types
    supported_extensions = 
      ['doc', 'docx', 'ppt', 'xls', 'html', 'odf', 'rtf', 'swf', 'svg', 'wpd', 'pdf', 'ods']
    supported_extensions.each do |ext|
      # make attachment.filename to return "document.#{ext}"
      attachment.stubs(:filename).returns("document.#{ext}")
      assert attachment.image_convertable?, "a .#{ext} document is image convertable"
    end

    # test unsupported file types
    unsupported_extensions = 
      ['txt', 'bin', 'cab', 'exe', 'jar', 'so', 'psd', 'ai', 'zip']
    unsupported_extensions.each do |ext|
      # make attachment.filename to return "document.#{ext}"
      attachment.stubs(:filename).returns("document.#{ext}")
      assert !attachment.image_convertable?, "a .#{ext} document is not image convertable"
    end
  end
  
  private
  
  # this is a bug fix of Docsplit for windows
  # it overides ImageExtractor.convert used in Attachment#render_to_image
  def fix_docsplit_extract_images_for_windows
    return unless windows?
    
    # Fix Docsplit::ImageExtractor#convert
    # convert tries to set enviroment variables via `VARIABLE=VALUE`
    # (get executed on command line). Thats the Linux way, but on Windows
    # variables have to assigned via `SET VARIABLE=VALUE`
    Docsplit::ImageExtractor.send :include, Docsplit::FixImageExtractor
  end

  def windows?
    host_os = (defined?("RbConfig") ? RbConfig : Config)::CONFIG['host_os']
    !!host_os.match(/mswin|windows|cygwin|mingw/i)
  end
  
  def assert_file_exists(relative)
    absolute = File.expand_path(relative)
    assert File.exists?(absolute), "Expected file #{relative.inspect} to exist, but does not"
  end
end