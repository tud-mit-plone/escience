require 'rails'
require 'redmine'

require_dependency 'will_paginate/array'

Redmine::Plugin.register :redmine_social do
  name 'redmine social plugin'
  author 'Christian Reichmann'
  description 'Extend your Redmine with social media'
  version '0.0.1'
end
