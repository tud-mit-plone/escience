require 'redmine'

Rails.configuration.to_prepare do
  require_dependency 'project'
  require_dependency 'mailer'
  require_dependency 'user'
  require 'redmine_doodles/patch_redmine_classes'
  
  Project.send(:include, ::Plugin::Doodles::Project)
  Mailer.send(:include, ::Plugin::Doodles::Mailer)
  User.send(:include, ::Plugin::Doodles::User)
end

require_dependency 'redmine_doodles/view_hooks'

Redmine::Search.map do |search|
  search.register :doodles
end
Redmine::Plugin.register :redmine_doodles do
  name 'Redmine Doodles plugin'
  author 'Felix Schaefer'
  description 'Per project doodles'
  version '0.5.1'
  url 'https://orga.fachschaften.org/projects/redmine_doodles'
  author_url 'http://orga.fachschaften.org/users/3'
  
  project_module :doodles do
    permission :manage_doodles, {:doodles => [:lock, :edit, :update]}, :require => :member
    permission :delete_doodles, {:doodles => [:destroy]}, :require => :member
    permission :create_doodles, {:doodles => [:new, :create, :preview]}, :require => :member
    permission :answer_doodles, {:doodle_answers => [:create, :update]}, :require => :loggedin
    permission :view_doodles, {:doodles => [:index, :show]}
  end
  
  menu :project_menu, :doodles, {:controller => 'doodles', :action => 'index'}, :caption => :label_doodle_plural, :param => :project_id
  
  activity_provider :doodles, :default => false, :class_name => ['Doodle', 'DoodleAnswersEdits']
end
