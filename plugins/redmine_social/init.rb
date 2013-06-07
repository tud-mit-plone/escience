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

  settings :default => { 
    :invitation_default_role_id => '3',
    :private_project_default_role_id => '4',
    'photo_content_type' => ['image/jpeg', 'image/png', 'image/gif', 'image/pjpeg', 'image/x-png', 'image/jpeg2000'],
    'photo_max_size' => '5' , 
    'photo_paperclip_options' => {
        :styles => {
            :thumb => {
              :geometry => "100x100#",
              :processors => [:cropper]
            },
            :medium => {
              :geometry => "180x180#",
              :processors => [:cropper]
            },
            :large => {
              :geometry => "465>",
              :processors => [:cropper]
            }
        },
        :path => ":rails_root/public/system/attachments/#{Rails.env}/files/:id/:style/:basename.:extension",
        :url => "/system/attachments/#{Rails.env}/files/:id/:style/:basename.:extension"}, 
        'photo_missing_thumb' => "avatar.png",
        'photo_missing_medium' => "avatar.png",
    },
    :partial =>'settings/redmine_social'

  contacts = Proc.new {"#{User.current.friendships.where("initiator = ? AND friendship_status_id = ?", false, FriendshipStatus[:pending].id).count}"}
  menu :account_menu, :user_contacts, {:controller => 'my', :action => 'render_block', :blockname => 'friendships', :blockaction => 'index', :tab => 'pending'}, :caption => {:value_behind => contacts, :text => :friendships}, :if => Proc.new{"#{contacts.call}".to_i > 0}
#  menu :account_menu, :user_contacts2, {:controller => 'friendships', :action => 'accepted', :user_id => Proc.new{"#{User.current.id}"}}, :caption => :friendships, :if => Proc.new{"#{contacts.call}".to_i == 0}
  menu :account_menu, :user_contacts2, {:controller => 'my', :action => 'render_block', :blockname => 'friendships', :blockaction => 'index'}, :caption => :friendships, :if => Proc.new{"#{contacts.call}".to_i == 0}

  project_module :user_calendar do 
    permission :appointments_add_watchers, :appointments => :add_watchers
  end
  user_module :user_clandar do 
    permission :view_calendar, {:calendar => [:show, :update]}, :read => true
  end
end

  
require_dependency 'application_helper'
ApplicationHelper.class_eval do
  DEFAULT_OPTIONS = {:size => 25,:alt => '',:title => '',:class => 'rounded_image'}
    def avatar(user, options = { })
      scale = options[:scale].nil? ? :thumb : options[:scale]
      options.delete(:scale)
      src = user.avatar ? user.avatar_photo_url(scale) : 'avatar.png'
      options[:size] = "#{options[:size]}x#{options[:size]}"
      options = DEFAULT_OPTIONS.merge(options)
      return image_tag src, options
    end
end