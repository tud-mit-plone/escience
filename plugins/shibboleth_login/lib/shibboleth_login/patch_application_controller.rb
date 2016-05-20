module ShibbolethLoginExtends
  module ApplicationControllerExtension
    module ClassMethods
    end
    module InstanceMethods
    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
      receiver.class_eval do
        def find_current_user
          user = nil
          uid = request.headers["Uid"]
          unless uid.nil?
            user = User.active.find_by_login(uid) rescue nil
            if user.nil?
              gender_map = {
                "1" => 'male',
                "2" => 'female',
              }
              user_data = {
                :firstname => request.headers["Cn"],
                :lastname => request.headers["Sn"],
                :mail => request.headers["email"],
                :confirm => true,
                :salutation => gender_map[request.headers["gender"]] || "",
              }
              user = User.new(user_data)
              user.login = uid
              user.activate!
              user.save!
              user.reload
            end
          end
          user
        end
      end
    end
  end
end
