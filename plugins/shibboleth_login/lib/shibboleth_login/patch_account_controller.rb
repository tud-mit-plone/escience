module ShibbolethLoginExtends
  module AccountControllerExtension
    module ClassMethods
    end
    module InstanceMethods
      def login_with_shibboleth
        unless shibboleth_enabled?
          return login_without_shibboleth
        end
        return_to = Rack::Utils.escape(request.env["HTTP_REFERER"] || url_for(controller: 'my', action: 'page'))
        redirect_to "#{Setting.plugin_shibboleth_login['shibboleth_path']}/Login?target=#{return_to}"
      end
      def logout_with_shibboleth
        unless shibboleth_enabled?
          return logout_without_shibboleth
        end
        return_to = Rack::Utils.escape(home_url)
        redirect_to "#{Setting.plugin_shibboleth_login['shibboleth_path']}/Logout?return=#{return_to}"
      end
      def register_with_shibboleth
        unless shibboleth_enabled?
          return register_without_shibboleth
        end
        render_404
      end
      def lost_password_with_shibboleth
        unless shibboleth_enabled?
          return lost_password_without_shibboleth
        end
        render_404
      end
      def activate_with_shibboleth
        unless shibboleth_enabled?
          return activate_without_shibboleth
        end
        render_404
      end
      private
      def shibboleth_enabled?
        Setting.plugin_shibboleth_login['enabled']
      end
    end

    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
      receiver.class_eval do
        alias_method_chain :login, :shibboleth
        alias_method_chain :logout, :shibboleth
        alias_method_chain :register, :shibboleth
        alias_method_chain :lost_password, :shibboleth
        alias_method_chain :activate, :shibboleth
      end
    end
  end
end
