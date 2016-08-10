module ShibbolethLoginExtends
  module ApplicationControllerExtension
    module ClassMethods
    end
    module InstanceMethods
      def find_current_user_with_shibboleth
        unless Setting.plugin_shibboleth_login['enabled']
          return find_current_user_without_shibboleth
        end
        user = nil
        uid = request.headers["Uid"]
        gender_map = {
          "1" => 'male',
          "2" => 'female',
        }
        user_data = {
          :firstname => request.headers["Cn"],
          :lastname => request.headers["Sn"],
          :mail => request.headers["mail"],
          :confirm => true,
          :salutation => gender_map[request.headers["gender"]] || "",
        }
        unless uid.nil?
          user = User.active.find_by_login(uid) rescue nil
          if user.nil?
            user = User.new(user_data)
            user.login = uid
            user.password = SecureRandom.hex(16)
            user.activate!
            user.save!
            user.reload
          # Shibboleth login is stateless, we have to cheat a bit: update
          # last login every 24 hours if the user is seen
          elsif user.updated_on < 1.day.ago
            user.update(user_data)
          end
          if user.last_login_on.nil? || user.last_login_on < 1.day.ago
            user.update_attribute(:last_login_on, Time.now)
          end
        end
        user
      end
    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
      receiver.class_eval do
        alias_method_chain :find_current_user, :shibboleth
      end
    end
  end
end
