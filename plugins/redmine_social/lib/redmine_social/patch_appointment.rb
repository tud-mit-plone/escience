module RedmineSocialExtends
    module WatcherExtension
      module ClassMethods
      end
      
      module InstanceMethods
      end
      
      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
            before_filter :authorize, :only => [:new, :destroy]
        end
      end
    end
    
    module AppointmentsControllerExtension
      module ClassMethods

      end
      module InstanceMethods

      end
      
      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          def edit
            @available_watchers = User.current.friendships.accepted.map{|f| f.friend}

            respond_to do |f| 
              f.html {render :action => 'edit'}
            end
          end          
        end
      end
    end
  end