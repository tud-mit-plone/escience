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

  test "rendered thumbnails for a pdf has the right size" do
    file = uploaded_test_file("lorem_hipsum_2_pager.pdf", "application/pdf")
    attachment = create_attachment(@container, @author, file)

    # Docsplit can create thumbnails for PDFs 
    assert attachment.image_convertable?
    
    page_count = Docsplit.extract_length(File.join(Attachment.storage_path, attachment.disk_filename)).to_i
    # render thumbnail for all pages of the PDF
    pages = 1..page_count
    size = 100 # in px
    pages.each do |page|
      output_file = attachment.render_to_image(
        :size => size,
        :pages => page,
        :render_page => page,
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
  
  test "supported file types are thumbnailable" do
    attachment = Attachment.new
    
    # test supported file types
    supported_extensions = 
      ['jpg', 'jpeg', 'gif', 'png', 'doc', 'docx', 'ppt', 'xls', 'html', 'odf', 'rtf', 'swf', 'svg', 'wpd', 'pdf', 'ods']
    supported_extensions.each do |ext|
      # make attachment.filename to return "document.#{ext}"
      attachment.stubs(:filename).returns("document.#{ext}")
      assert attachment.thumbnailable?, "a .#{ext} document is thumbnailable"
    end

    # test unsupported file types
    unsupported_extensions = 
      ['txt', 'bin', 'cab', 'exe', 'jar', 'so', 'psd', 'ai', 'zip']
    unsupported_extensions.each do |ext|
      # make attachment.filename to return "document.#{ext}"
      attachment.stubs(:filename).returns("document.#{ext}")
      assert !attachment.thumbnailable?, "a .#{ext} document is not thumbnailable"
    end
  end
  
  test "thumbnail returns an image with the right size" do
    # images converted by Redmine, documents like PDFs by redmine_social
    # so test this two types at onces
    
    # upload a jpeg
    file = uploaded_test_file("simons_cat.jpg", "image/jpeg")
    image_attachment = create_attachment(@container, @author, file)
    
    # upload a pdf 
    file = uploaded_test_file("lorem_hipsum_2_pager.pdf", "application/pdf")
    pdf_attachment = create_attachment(@container, @author, file)
    
    # jpeg thumbnail
    thumbnail_file = image_attachment.thumbnail(:size => 100)
    assert_file_exists thumbnail_file
    thumbnail = Magick::Image::read(thumbnail_file).first
    assert_not_nil thumbnail
    width, height = thumbnail.columns, thumbnail.rows
    # either width or height is 100px. the other side should less or equal
    assert_equal 100, [width, height].max
    
    # pdf thumbnail
    thumbnail_file = pdf_attachment.thumbnail(:size => 100)
    assert_file_exists thumbnail_file
    thumbnail = Magick::Image::read(thumbnail_file).first
    assert_not_nil thumbnail
    width, height = thumbnail.columns, thumbnail.rows
    # either width or height is 100px. the other side should less or equal
    assert_equal 100, [width, height].max
  end
  
  private
  
  def create_attachment(container, author, file)
    User.current = author
    
    # An Attachment needs at least one MetaInformation
    meta = MetaInformation.new(
      :meta_information => 'Foo',
      :user => author
    )
    meta.save!
    
    attachment = Attachment.new(
      :container => @container,
      :file => file,
      :author => author,
      :meta_information => [meta]
    )
    attachment.save!
    
    attachment
  end
  
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