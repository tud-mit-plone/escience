module RedmineSocialExtends
  module SettingsHelperExtension
    module ClassMethods
    end
    module InstanceMethods
      def generate_select_from_key(key,value,name_pre,display_attribute="name")
        keysplit = key.split('_')
        begin 
          return nil if keysplit.length < 2
          obj = keysplit[keysplit.length-2].camelcase.constantize
          if keysplit.last == 'id' && !obj.nil?
            return select_tag("#{name_pre}[#{key}]",options_from_collection_for_select(obj.all, 'id', display_attribute,value.to_i))
          end
        rescue NameError => e
        
        end
        return nil
      end

      def settings_hash_to_html(settings,name_pre="settings")
        html = ""
        settings.each do |k,v| 
          unless v.class == Hash || v.class == HashWithIndifferentAccess
            html << "<label>#{name_pre.to_s.gsub("_"," ").gsub("["," ").gsub("]","=>")} #{k.to_s.gsub("_"," ")}</label><br />"
            selectable = generate_select_from_key(k,v,name_pre)
            if !selectable.nil?
              html << selectable
            else
              html << text_field_tag("#{name_pre}[#{k}]",v, :size => "#{v.length > 40 ? 80 : 40}")
            end
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