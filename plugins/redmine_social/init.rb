require 'rails'
require 'redmine'

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

  contacts = Proc.new {"#{User.current.friendships.where("initiator = ? AND friendship_status_id = ?", false, FriendshipStatus[:pending].id).count}"}
  menu :private_menu, :user_contacts, {:controller => 'my', :action => 'render_block', :blockname => 'friendships', :blockaction => 'index', :tab => 'pending'}, :caption => {:value_behind => contacts, :text => :friendships}, :if => Proc.new{"#{contacts.call}".to_i > 0}, :html => {:class => "icon icon-user"}
  menu :private_menu, :user_contacts2, {:controller => 'my', :action => 'render_block', :blockname => 'friendships', :blockaction => 'index'}, :caption => :friendships, :if => Proc.new{"#{contacts.call}".to_i == 0}, :html => {:class => "icon icon-group"}


  Redmine::AccessControl.map do |map|
    map.permission :group_invitations_create, :group_invitations => [:create], :require => :member
    map.permission :view_calendar, {:calendar => [:show, :update]}, :read => true
    map.permission :appointments_add_watchers, :appointments => :add_watchers
    map.permission :group_invitations_create, :group_invitations => :create
  end

  Redmine::Search.map do |search|
    search.register :users, :sort_function => 'sort', :limit_date_function => 'updated_on', :show_result_partial => 'users/show',
                             :show_result_partial_locals => Proc.new {|e|  {:user => e, :memberships => e.memberships}}
    search.register :attachments, :sort_function => 'sort',
                             :show_result_partial_locals => Proc.new {|e|  {:attachment => e}}
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
