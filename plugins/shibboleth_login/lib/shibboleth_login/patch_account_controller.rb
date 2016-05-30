module ShibbolethLoginExtends
  module AccountControllerExtension
    module ClassMethods
    end
    module InstanceMethods
      def login_with_shibboleth
        unless Setting.plugin_shibboleth_login['enabled']
          return login_without_shibboleth
        end
        return_to = Rack::Utils.escape(request.env["HTTP_REFERER"] || url_for(controller: 'my', action: 'page'))
        redirect_to "#{Setting.plugin_shibboleth_login['shibboleth_path']}/Login?target=#{return_to}"
      end
      def logout_with_shibboleth
        unless Setting.plugin_shibboleth_login['enabled']
          return logout_without_shibboleth
        end
        return_to = Rack::Utils.escape(home_url)
        redirect_to "#{Setting.plugin_shibboleth_login['shibboleth_path']}/Logout?target=#{return_to}"
      end
    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
      receiver.class_eval do
        alias_method_chain :login, :shibboleth
        alias_method_chain :logout, :shibboleth
      end
    end
  end
end
