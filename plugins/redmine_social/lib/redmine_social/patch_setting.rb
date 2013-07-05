module RedmineSocialExtends
  module SettingsHelperExtension
    module ClassMethods
    end
    module InstanceMethods
      def settings_hash_to_html(settings,name_pre="settings")
        html = ""
        settings.each do |k,v| 
          unless v.class == Hash || v.class == HashWithIndifferentAccess
            html << "<label>#{name_pre.to_s.gsub("_"," ").gsub("["," ").gsub("]","=>")} #{k.to_s.gsub("_"," ")}</label><br />"
            html << text_field_tag("#{name_pre}[#{k}]",v, :size => "#{v.length > 40 ? 80 : 40}")
            html << "<br />"
          else
            html << settings_hash_to_html(v,"#{name_pre}[#{k}]")
          end
        end
        return html.html_safe
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