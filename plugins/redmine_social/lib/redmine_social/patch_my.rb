module RedmineSocialExtends
  module MyControllerExtension
    module ClassMethods
    end
    
    module InstanceMethods
      def interest_search

        q = "%#{params[:q]}%"
        interest_tag = User.interest_counts.arel_table
        interests = User.interest_counts.where(interest_tag[:name].matches(q))

        respond_to do |format|
          format.xml { render :xml => interests }
          format.json { render :json => interests }
        end
      end

      def skill_search

        q = "%#{params[:q]}%"
        skill_tag = User.skill_counts.arel_table
        skills = User.skill_counts.where(skill_tag[:name].matches(q))

        respond_to do |format|
          format.xml { render :xml => skills }
          format.json { render :json => skills }
        end
      end

      def prepare_tag_params(tag_list)
        tag_list = tag_list.split(',')
        ids = []
        tags = []

        tag_list.each do |tag|
          if(tag =~ /^[0-9]+$/)
            tags << ActsAsTaggableOn::Tag.where(:id => tag).map(&:name)
          else
            tags << tag.gsub(" ","")
          end
        end
        return tags
      end
    end
    
    def self.included(receiver)
      receiver.extend         ClassMethods
      receiver.send :include, InstanceMethods
      receiver.class_eval do
        helper ProjectsHelper        

        def render_block
          if params['blockname'].nil?
            redirect_to :action => 'index', :user_id => User.current.id
          else
            action = params['blockaction'].nil? ? 'index' : params['blockaction']
            url = {:controller => params['blockname'], :action => params['blockaction'], :user_id => User.current.id}
            redirect_to url.merge!(params.except(:controller, :action,:blockaction, :blockname))
          end
        end

          # Edit user's account
        def account
          @user = User.current
          @pref = @user.pref
          if request.post?
            @user.safe_attributes = params[:user]
            @user.pref.attributes = params[:pref]
            @user.pref[:no_self_notified] = (params[:no_self_notified] == '1')
            @user.login = params[:user][:mail]
            
            @user.security_number = User.calc_security_number(params[:security])

            new_tags = prepare_tag_params(params[:my_interest])
            @user.interest_list = new_tags.uniq
            new_tags = prepare_tag_params(params[:my_skill])
            @user.skill_list = new_tags.uniq

            @user.private_project.enabled_module_names = params[:enabled_module_names]
            @user.private_project.save!

            if  params[:wiki].nil? == false && params[:wiki][:start_page].nil? == false 
              @wiki = @user.private_project.wiki || Wiki.new(:project => @user.private_project)
              @wiki.safe_attributes = params[:wiki]
              @wiki.save!
            end

            @user.save!
            if @user.save
              @user.pref.save
              @user.notified_project_ids = (@user.mail_notification == 'selected' ? params[:notified_project_ids] : [])
              set_language_if_valid @user.language
              flash[:notice] = l(:notice_account_updated)
              redirect_to :action => 'account', :sub => 'my_account'
              return
            end
          end
        end

      end
    end
  end
end
