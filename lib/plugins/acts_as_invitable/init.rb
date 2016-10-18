require File.dirname(__FILE__) + '/lib/acts_as_invitable'
ActiveRecord::Base.send(:include, Redmine::Acts::Invitable)
