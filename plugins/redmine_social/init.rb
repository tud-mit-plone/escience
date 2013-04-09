require 'rails'
require 'redmine'

Dir::foreach(File.join(File.dirname(__FILE__), 'lib')) do |file|
  next if /\.{1,2}/ =~ file
  next unless File.exist?(File.join(File.dirname(__FILE__), 'lib',file,"init.rb"))
  p "redmine_social requires #{File.join(File.dirname(__FILE__), 'lib',file,"init.rb")}"
  require File.join(File.dirname(__FILE__), 'lib',file,"init.rb")
end

require "#{File.join(File.dirname(__FILE__), 'lib','paperclip_processors')}/cropper"
#require "hpricot"

#require_dependency 'communityengine'
#require_dependency 'plugins/enumerations_mixin/init.rb'

#require_dependency 'meta_search'
require_dependency 'will_paginate/array'

Redmine::Plugin.register :redmine_social do
  name 'redmine social plugin'
  author 'Christian Reichmann'
  description 'Extend your Redmine with social media'
  version '0.0.1'

  settings :default => { 'photo_content_type' => ['image/jpeg', 'image/png', 'image/gif', 'image/pjpeg', 'image/x-png', 'image/jpeg2000'], 'photo_max_size' => '5' , 
                                    'photo_paperclip_options' => {:styles => { 
                                                                                                :thumb => { 
                                                                                                      :geometry => "100x100#", 
                                                                                                      :processors => [:cropper]},
                                                                                                :medium => "290x320#",
                                                                                                :large => "465>"}, 
                                                                                      :path => ":rails_root/public/system/attachments/#{Rails.env}/files/:id/:style/:basename.:extension",
                                                                                      :url => "/system/attachments/#{Rails.env}/files/:id/:style/:basename.:extension"}, 
                                    'photo_missing_thumb' => '',
                                    'photo_missing_medium' => '' },
                                   :partial =>'settings/redmine_social'

  # settings :default => {'bbb_server' => '', 'bbb_salt' => ''}, :partial => 'settings-bbb/settings'
  
  # project_module :bigbluebutton do
  #   permission :bigbluebutton_join, :bbb => :start
  #   permission :bigbluebutton_start, :bbb => :start_form
  #   permission :bigbluebutton_moderator, :bbb => :create
  # end

  # Project.has_and_belongs_to_many(:bbb_servers)

end