# Load the Redmine helper
require File.expand_path(File.dirname(__FILE__) + '/../../../test/test_helper')
require "../init.rb"

#require 'active_record'
#require 'active_record/fixtures'
 
#Fixtures.create_fixtures('./fixtures/', ActiveRecord::Base.connection.tables)


# Ensure that we are using the temporary fixture path
#class ActiveSupport::TestCase
#  self.fixture_path = File.dirname(__FILE__) + '/../fixtures/'
#
#  def initialize
#  	Rails.logger.info "----------->" + __FILE__
#  	$stderr.puts "foo bar ---------000000"
#  end
#end