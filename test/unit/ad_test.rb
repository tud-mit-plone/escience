require File.expand_path('../../../../../test/test_helper', __FILE__)

class AdTest < ActiveSupport::TestCase
  DUMMY_AD_HTML = "<strong>Buy the new Foo now!</strong>"
  
  def setup
    # track all changes during the test to rollback
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.start
  end
  
  def teardown
    # rollback any changes during the test
    DatabaseCleaner.clean
  end
  
  test "ad must have required fields" do
    ad = Ad.new
    assert !ad.save
    assert !ad.errors[:html].empty?
  end
  
  test "ad audience must be in set" do
    # Ad with a non existing audience is not valid
    ad = Ad.new(:html => DUMMY_AD_HTML, :audience => 'foo', :frequency => 1)
    assert !ad.save
    assert !ad.errors[:audience].empty?
    
    # Ad with existing audience is valid
    Ad::AUDIENCES.each do |audience|
      ad = Ad.new(:html => DUMMY_AD_HTML, :audience => audience, :frequency => 1)
      ad.valid? # result of validation is in ad.errors
      assert ad.errors[:audience].empty?
    end
  end
  
  test "ad frequency must be in range" do
    # Ad with a frequency out of range is not valid
    ad = Ad.new(:html => DUMMY_AD_HTML, :audience => 'all', :frequency => 0)
    assert !ad.save
    assert !ad.errors[:frequency].empty?
    
    # Ad with frequency in range is valid
    Ad::FREQUENCIES.each do |frequency|
      ad = Ad.new(:html => DUMMY_AD_HTML, :audience => 'all', :frequency => frequency)
      ad.valid? # result of validation is in ad.errors
      assert ad.errors[:frequency].empty?
    end
  end
  
  test "start_date have to be before end_date" do
    start_date = Time.new(2013, 10, 18)
    end_date = Time.new(2014, 1, 10)
    
    # Ad with start_date > end_date
    ad = Ad.new(
      :html => DUMMY_AD_HTML,
      :audience => 'all',
      :frequency => 1,
      :time_constrained => true,
      :start_date => end_date,
      :end_date => start_date
    )
    assert !ad.save
    assert !ad.errors[:start_date].empty? or !ad.errors[:end_date].empty?
  end
  
  test "start_date and end_date have to be set when time_constrained" do
    ad = Ad.new(:html => DUMMY_AD_HTML, :audience => 'all', :frequency => 1,
      :time_constrained => true)
    assert !ad.save
    assert !ad.errors[:start_date].empty? or !ad.errors[:end_date].empty?
    
    ad = Ad.new(:html => DUMMY_AD_HTML, :audience => 'all', :frequency => 1,
      :time_constrained => false,
      :start_date => Time.new(2013, 10, 18),
      :end_date => Time.new(2014, 1, 10))
    assert !ad.save
    assert !ad.errors[:time_constrained].empty? or !ad.errors[:start_date].empty? or !ad.errors[:end_date].empty?
  end
  
  test "display lists only ads for the right audience" do   
    # Ads for all
    Ad.create(:location => 'foo', :published => true, :html => '<p>all</p>', :audience => 'all', :frequency => 1)
    Ad.create(:location => 'foo', :published => true, :html => '<p>all</p>', :audience => 'all', :frequency => 1)
    # Ads for logged_in
    Ad.create(:location => 'foo', :published => true, :html => '<p>logged_in</p>', :audience => 'logged_in', :frequency => 1)
    Ad.create(:location => 'foo', :published => true, :html => '<p>logged_in</p>', :audience => 'logged_in', :frequency => 1)
    # Ads for logged_out
    Ad.create(:location => 'foo', :published => true, :html => '<p>logged_out</p>', :audience => 'logged_out', :frequency => 1)
    Ad.create(:location => 'foo', :published => true, :html => '<p>logged_out</p>', :audience => 'logged_out', :frequency => 1)
    
    # display returns a random ad, so we have to test multiple times
    (1..100).each do
      logged_in = true
      ad_html = Ad.display('foo', logged_in)
      assert ((ad_html.include? 'all') or (ad_html.include? 'logged_in')),
        "Ad #{ad_html} should for audience all or logged_in"
      
      logged_in = false
      ad_html = Ad.display('foo', logged_in)
      assert ((ad_html.include? 'all') or (ad_html.include? 'logged_out')),
        "Ad #{ad_html} should for audience all or logged_out"
    end
  end
end