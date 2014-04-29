module RedmineSocialExtends
  module ApplicationControllerExtension
    module ClassMethods
    end
    module InstanceMethods
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
      receiver.class_eval do
        def set_user_session_scope
          scope_view = params[:scope_select].to_i
          
          if scope_view < 0 || scope_view > 3
            render status: 403, json: "Forbidden".to_json
          elsif(scope_view > 2)
            session[:current_view_of_eScience] = User.current.admin? ? scope_view.to_s : '0'
            render status: 200, json: session[:current_view_of_eScience].to_json
          else 
            session[:current_view_of_eScience] = scope_view.to_s
            render status: 200, json: session[:current_view_of_eScience].to_json
          end
        end

        def generate_qr_code(url = params[:p_url], size_x=30, size_y=30)
          qr = nil
          qr_size = 3
          while(qr == nil && qr_size < 10)
            begin
              qr = RQRCode::QRCode.new( url, :size => qr_size, :level => :h )
              png = qr.to_img
              send_data(png.resize(size_x, size_y), :type => 'image/png', :disposition => 'inline')
            rescue RQRCode::QRCodeRunTimeError => e
              qr_size += 1
            end
          end
        end
      end
    end
  end
end