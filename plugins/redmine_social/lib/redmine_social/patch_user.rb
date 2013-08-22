  module RedmineSocialExtends
    module UserExtension
      module ClassMethods
      end
      
      module InstanceMethods
         def avatar_photo_url(size = :original)
          if avatar
             avatar.photo.url(size)
          else
            case size
              when :thumb
                Setting.plugin_redmine_social['photo_missing_thumb']
              else
                Setting.plugin_redmine_social['photo_missing_medium']
            end
          end
        end
        
        def sort
          self.lastname + self.firstname 
        end

        def can_request_friendship_with(user)
          !self.eql?(user) && !self.friendship_exists_with?(user)
        end

        def friendship_exists_with?(friend)
          Friendship.find(:first, :conditions => ["user_id = ? AND friend_id = ?", self.id, friend.id])
        end

        def has_reached_daily_friend_request_limit?
          friendships_initiated_by_me.count(:conditions => ['created_on > ?', Time.now.beginning_of_day]) >= Friendship.daily_request_limit
        end

        def create_private_project(user=self)
          logger.info ("user.private_project.nil? :: #{user.private_project}")
          if user.private_project.nil? 
            prj = Project.new({:name => user.login, :is_public => false, :identifier => Digest::MD5.hexdigest(Time.now.to_i.to_s).to_s, :is_private_project => true})
            prj.enabled_modules = []
            prj.tracker_ids = []
            prj.custom_value_ids=[] 
            prj.save!
            m = Member.new(:user_id => user.id, :project => prj, :role_ids => [Setting.plugin_redmine_social['private_project_default_role_id']])
            m.save!
            prj.exclusive_user = user 
          end
        end

        # #necessary for search function
        # def visible?(user=User.current)
        #   true
        # end
      end
      
      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do

          acts_as_tagger 
          acts_as_taggable_on :skills, :interests
          
          #set error message from max characters to max length
          validates :interest_list, length: { maximum: 5 }
          validates :skill_list, length: { maximum: 5 }
          
          acts_as_searchable :columns => ['mail', 'firstname', 'lastname'],:with_tagging => true
          
          #photos 
          has_many :photos, :order => "created_at desc", :dependent => :destroy
          #albums 
          has_many :albums, :dependent => :destroy
          #avatar
          belongs_to  :avatar, :class_name => "Photo", :foreign_key => "avatar_id", :inverse_of => :user_as_avatar
          #friendship associations
          has_many :friendships, :class_name => "Friendship", :foreign_key => "user_id", :dependent => :destroy
          has_many :accepted_friendships, :class_name => "Friendship", :conditions => ['friendship_status_id = ?', 2]
          has_many :pending_friendships, :class_name => "Friendship", :conditions => ['initiator = ? AND friendship_status_id = ?', false, 1]
          has_many :friendships_initiated_by_me, :class_name => "Friendship", :foreign_key => "user_id", :conditions => ['initiator = ?', true], :dependent => :destroy
          has_many :friendships_not_initiated_by_me, :class_name => "Friendship", :foreign_key => "user_id", :conditions => ['initiator = ?', false], :dependent => :destroy
          has_many :occurances_as_friend, :class_name => "Friendship", :foreign_key => "friend_id", :dependent => :destroy
          #private project 
          #belongs_to :private_project, :autosave => true, :dependent => :destroy, :class_name => 'Project', :foreign_key => 'id'
          belongs_to :private_project, :class_name => "Project", :foreign_key => "private_project_id"

          #necessary for search function
          scope :visible, lambda {|*args| { }  } 
        end
      end
    end
        
    module UsersController
      module ClassMethods

      end
      module InstanceMethods
        def upload_profile_photo
          @user = User.find(params[:id])
          @avatar = Photo.new(params[:photo])
          @avatar.name = params[:photo][:filename] 
          @avatar.user  = @user
          if @avatar.save
            @user.avatar_id  = @avatar.id
            @user.save!

            @photo = @avatar
          end

          respond_to do |format|
            format.html { render :action => 'show', :layout => false if request.xhr? }
            format.js { render :partial => 'crop_profile_photo' }
          end
        end
        
          def tag_search
            tags = []
            if params[:q].nil? || params[:q]== '' || params[:q].split('').length < 3
              tags
            else
              tags = ActsAsTaggableOn::Tag.where("name like ?",params[:q])
            end
            
            respond_to do |format|
              format.xml { render :xml => tags }
              #format.js # user_search.js.erb
              #format.json { render :json => @projects }
            end
          end

        def crop_profile_photo
          @user = User.find(params[:id])
          @avatar = @user.avatar ? @user.avatar : Photo.new(params[:photo]) 
          @photo = @avatar
          unless params[:avatar_id].nil?
            @user.avatar_id  = params[:avatar_id]
            @user.save!
          end
          return unless request.put?
          @photo.update_attributes(:crop_x => params[:photo][:crop_x], 
                                                    :crop_y => params[:photo][:crop_y], 
                                                    :crop_w => params[:photo][:crop_w], 
                                                    :crop_h => params[:photo][:crop_h])
          respond_to do |format|
            format.html { redirect_to my_account_path }
            format.js { render :partial => 'users/update_profile_photo' }
          end
        end
      end
      
      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          before_filter :require_admin, :except => [:show, :user_search, :contact_member_search, :online_live_count, :crop_profile_photo, :upload_profile_photo]
          layout 'base'

          def update
            @user.admin = params[:user][:admin] if params[:user][:admin]
            @user.login = params[:user][:login] if params[:user][:login]
            @user.confirm = params[:user][:confirm] if params[:user][:confirm]
            if params[:user][:password].present? && (@user.auth_source_id.nil? || params[:user][:auth_source_id].blank?)
              @user.password, @user.password_confirmation = params[:user][:password], params[:user][:password_confirmation]
            end
            @user.safe_attributes = params[:user]
            # Was the account actived ? (do it before User#save clears the change)
            was_activated = (@user.status_change == [User::STATUS_REGISTERED, User::STATUS_ACTIVE])
            # TODO: Similar to My#account
            @user.pref.attributes = params[:pref]
            @user.pref[:no_self_notified] = (params[:no_self_notified] == '1')

            if @user.save
              @user.pref.save
              @user.notified_project_ids = (@user.mail_notification == 'selected' ? params[:notified_project_ids] : [])

              @user.create_private_project()

              if was_activated
                Mailer.account_activated(@user).deliver
              elsif @user.active? && params[:send_information] && !params[:user][:password].blank? && @user.auth_source_id.nil?
                Mailer.account_information(@user, params[:user][:password]).deliver
              end

              respond_to do |format|
                format.html {
                  flash[:notice] = l(:notice_successful_update)
                  redirect_to_referer_or edit_user_path(@user)
                }
                format.api  { render_api_ok }
              end
            else
              @auth_sources = AuthSource.find(:all)
              @membership ||= Member.new
              # Clear password input
              @user.password = @user.password_confirmation = nil

              respond_to do |format|
               
                format.html { 
                 flash[:notice] = @user.errors.full_messages
                 render :action => :edit }
                format.api  { render_validation_errors(@user) }
              end
            end
          end

        end
      end
    end
  end