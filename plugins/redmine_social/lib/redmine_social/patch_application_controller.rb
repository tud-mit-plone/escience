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
