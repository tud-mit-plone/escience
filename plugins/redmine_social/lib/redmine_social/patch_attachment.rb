  module RedmineSocialExtends
    module AttachmentExtension
      module ClassMethods
      end
      
      module InstanceMethods

        def sort
          self.filename 
        end

         def render_to_image(options=nil)
           attachment =  options && options[:attachment] ? options[:attachment] : self 
           size = options && options[:size] ? options[:size] : '100x' 
           pages = options && options[:pages] ? options[:pages] : 1
           output = options && options[:output] ? options[:output] : '/tmp/escience'
           input = options && options[:input] ? options[:input] : File.join(Rails.root, "files")
           render_page = options && options[:render_page] ? options[:render_page] : 1

           filename_without_extension = attachment.disk_filename.to_s.match(/(.*)(\.)/)[1]
           begin
             max_pages = Docsplit.extract_length(File.join(input,attachment.disk_filename)).to_i
           rescue => e 
             logger.error "An error occured while generating thumbnail for attachment#id: #{attachment.id}\nException was: #{e.message}" if logger
             logger.error "#{e.backtrace}"
             max_pages = 1
           end

           
           render_page = render_page.to_i > max_pages ? 1 : render_page
           pages = pages.to_i > max_pages ? 1 : pages

           begin
             Docsplit.extract_images(File.join(input,attachment.disk_filename),:size => size,:output => output ,:format => [:jpg], :pages => pages)
           rescue => e 
              logger.error "An error occured while generating thumbnail for attachment#id: #{attachment.id}\nException was: #{e.message}" if logger
           end

           render_file = "#{File.join(output,"#{filename_without_extension}_#{render_page}.jpg")}"
           return render_file
         end

        def image_convertable?
          !!(self.filename =~ /\.(doc|docx|ppt|xls|html|odf|rtf|swf|svg|wpd|pdf|ods)$/i)
        end
      end
      
      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          acts_as_searchable :columns => ['filename'], :foreign_column => :meta_information
          
          #necessary for search function
          scope :visible, lambda {|*args| { } } 
          
          def thumbnailable?
            image? || image_convertable?
          end

          # Returns the full path the attachment thumbnail, or nil
          # if the thumbnail cannot be generated.
          def thumbnail(options={})
            size = options[:size].to_i
            if size > 0
              # Limit the number of thumbnails per image
              size = (size / 50) * 50
              # Maximum thumbnail size
              size = 800 if size > 800
            else
              size = Setting.thumbnails_size.to_i
            end
            
            size = 100 unless size > 0
            
            if image? && readable?
              target = File.join(self.class.thumbnails_storage_path, "#{id}_#{digest}_#{size}.thumb")
              begin
                return Redmine::Thumbnail.generate(self.diskfile, target, size)
              rescue => e
                logger.error "An error occured while generating thumbnail for #{disk_filename} to #{target}\nException was: #{e.message}" if logger
                return nil
              end           
            end
            if image_convertable? && readable?
              options[:size] = "#{size}x"
              options[:render_page] = (!(options[:pages].nil?) && options[:pages].match(/^\d+$/)) ? options[:pages].to_i : nil 
              return render_to_image(options)
            end
          end          
        end
      end
    end
    
    module AttachmentsControllerExtension
      module ClassMethods

      end
      module InstanceMethods

      end
      
      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          def show
            type = detect_content_type(@attachment)

            respond_to do |format|
              format.js {
                if type == 'application/octetstream' && @attachment.disk_filename.split(".").last == 'pdf' ||
                       type == 'application/pdf'
                  render :render_show
                elsif type == 'application/vnd.ms-excel' && @attachment.disk_filename.split(".").last == 'xls' ||
                       type == 'application/vnd.oasis.opendocument.spreadsheet'
                  sent_render_to_image({:size => '1000x',:pages => params[:pages]})
                  render :render_show
                else 
                  render :render_show
                end
              }
              format.html {
                
                if @attachment.is_diff?
                  @diff = File.new(@attachment.diskfile, "rb").read
                  @diff_type = params[:type] || User.current.pref[:diff_type] || 'inline'
                  @diff_type = 'inline' unless %w(inline sbs).include?(@diff_type)
                  # Save diff type as user preference
                  if User.current.logged? && @diff_type != User.current.pref[:diff_type]
                    User.current.pref[:diff_type] = @diff_type
                    User.current.preference.save
                  end
                  render :action => 'diff'
                elsif @attachment.is_text? && @attachment.filesize <= Setting.file_max_size_displayed.to_i.kilobyte
                  @content = File.new(@attachment.diskfile, "rb").read
                  render :action => 'file'
                elsif type == 'application/octetstream' && @attachment.disk_filename.split(".").last == 'pdf' ||
                       type == 'application/pdf'
                  render :action => 'render_show'
                elsif type == 'application/vnd.ms-excel' && @attachment.disk_filename.split(".").last == 'xls' ||
                       type == 'application/vnd.oasis.opendocument.spreadsheet'
                  sent_render_to_image({:size => '1000x',:pages => params[:pages]})
                else
                  download
                end
              }
              format.api {
                render :render_show
              }
            end
          end
          
          # def download
          #   if @attachment.container.is_a?(Version) || @attachment.container.is_a?(Project)
          #     @attachment.increment_download
          #   end
          #   diskfile = @attachment.thumbnail({:size => 300, :pages => params[:pages]}) 
            
          #   if stale?(:etag => diskfile)
          #     # images are sent inline
          #     send_file diskfile, :filename => filename_for_content_disposition(diskfile),
          #                                     :type => 'jpeg',
          #                                     :disposition => (@attachment.image? ? 'inline' : 'attachment')
          #   end
          # end

          def thumbnail
            thumbnail = @attachment.thumbnail({:size => params[:size], :pages => params[:pages]})
            if @attachment.thumbnailable? && thumbnail && File.exist?(thumbnail)
              if stale?(:etag => thumbnail)
                send_file thumbnail,
                  :filename => thumbnail,
                  :type =>  'image/jpeg',
                  :disposition => 'inline'
              end
            else
              # No thumbnail for the attachment or thumbnail could not be created
              render :nothing => true, :status => 404
            end
          end

          def sent_render_to_image(options=nil)
            render_file = @attachment.render_to_image(options)
            send_file render_file, :filename =>render_file,
                        :type => 'image/jpeg',
                        :disposition => 'inline' 
          end   
        end
      end
    end
  end