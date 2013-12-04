module RedmineSocialExtends
    module CommentsControllerExtension
      module ClassMethods
      end
      
      module InstanceMethods
      end
      
      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          before_filter :find_model_object
          before_filter :find_project_from_association
          before_filter :authorize
#          before_filter :find_model_object, :only => [:create, :destroy]
#          before_filter :find_project_from_association, :only => [:create, :destroy]
#          before_filter :authorize, :only => [:create, :destroy] # TODO: for all functions please ... but not for now

          def create_general_comment
            model = nil
            #Todo: Refactor read from acts_as_commentable
            ["news_id","album_id","photo_id"].each do |id|
              next if params[id.to_sym].nil?
              model = id.split('_').first.capitalize.singularize.classify.constantize.find(params[id.to_sym])
            end
            logger.info "model: #{model}"
            #raise Unauthorized unless @news.commentable?

            comment = Comment.new
            comment.safe_attributes = params[:comment]
            comment.author = User.current
            if model.comments << comment
              flash[:notice] = l(:label_comment_added)
            end
            redirect_to :controller => model.class.name.tableize.to_sym, :action => 'show', :id => model.id
          end
        end
      end
    end
  end