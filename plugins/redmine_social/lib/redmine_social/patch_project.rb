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
        end
      end
    end
    module ProjectsHelperExtension
      module ClassMethods
      end

      module InstanceMethods
      end

      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do

        end
      end
    end
  end
