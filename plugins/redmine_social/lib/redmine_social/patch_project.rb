module RedmineSocialExtends
    module ProjectsExtension
      module ClassMethods
      end
      
      module InstanceMethods
      end
      
      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          acts_as_invitable

          has_many :albums, as: :container, :dependent => :destroy
          has_one :exclusive_user, :class_name => 'User', :foreign_key => 'private_project_id'
        end
      end
    end
    module ProjectsHelperExtension
      module ClassMethods
      end
      
      module InstanceMethods
        def private_project_settings_tabs(project=nil)
          tabs = [{:name => 'modules', :action => :select_project_modules, :partial => 'projects/settings/modules', :label => :label_module_plural},
            {:name => 'repositories', :action => :manage_repository, :partial => 'projects/settings/repositories', :label => :label_repository_plural},
            {:name => 'activities', :action => :manage_project_activities, :partial => 'projects/settings/activities', :label => :enumeration_activities}
            ]
            tabs << {:name => 'wiki', :action => :manage_wiki, :partial => 'projects/settings/wiki', :label => :label_wiki} if project.nil? == false && project.module_enabled?('wiki')
            return tabs
          #logger.info ("TRodules #{JSON.parse(Setting.plugin_redmine_social['private_project_modules']).class}")
          #tab = Setting.plugin_redmine_social['private_project_modules'].class == Array ? Setting.plugin_redmine_social['private_project_modules'] : 
          #          Setting.plugin_redmine_social['private_project_modules'].to_s.split(" ")
        end
      end
      
      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          
        end
      end
    end
  end