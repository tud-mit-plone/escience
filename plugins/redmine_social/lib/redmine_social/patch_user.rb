  module RedmineSocialExtends
    module UserExtension
      module ClassMethods
        @@security_hash={:searchable_sql => '1', :account_readable_for_user => '2'}
        def security_hash
          return @@security_hash
        end

        def calc_security_number(sec_hash)
          return if User.security_hash.nil? 
          sec_number = 0 

          unless sec_hash.nil?
            User.security_hash.keys.each do |sec_option|
              sec_number += User.security_hash[sec_option].to_i if sec_hash.include?(sec_option)
            end 
          end
          return sec_number
        end

        def method_missing(method_name, *args, &block)
          if @@security_hash.keys.include?(method_name.to_sym)
            return @@security_hash[method_name.to_sym].to_i
          else
            super
          end
        end
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
        
        def selected_security_options()
          selected_sec_options = []
          User.security_hash.keys.each do |sec_option|
            selected_sec_options << sec_option if((self.security_number.to_i & User.security_hash[sec_option].to_i) > 0)
          end 
          return selected_sec_options
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
          validates :interest_list, length: { maximum: 20 }
          validates :skill_list, length: { maximum: 20 }
          
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

            def allowed_to?(action, context, options={}, &block)
              if context && context.is_a?(Project)
                return false unless context.allows_to?(action)
                # Admin users are authorized for anything else
                return true if admin?

                roles = roles_for_project(context)
                return false unless roles
                roles.any? {|role|
                  (context.is_public? || role.member?) &&
                  role.allowed_to?(action) &&
                  (block_given? ? yield(role, self) : true)
                }
            elsif context && context.is_a?(Array)
              if context.empty?
                false
              else
                # Authorize if user is authorized on every element of the array
                context.map {|project| allowed_to?(action, project, options, &block)}.reduce(:&)
              end
            elsif options[:global]
              # Admin users are always authorized
              return true if admin?

              # authorize if user has at least one role that has this permission
              roles = memberships.collect {|m| m.roles}.flatten.uniq
              roles << (self.logged? ? Role.non_member : Role.anonymous)
              roles.any? {|role|
                role.allowed_to?(action) &&
                (block_given? ? yield(role, self) : true)
              }
            elsif(context.is_a?(User))
              if((User.current.id.to_i == context.id.to_i) || 
                (User.where(:id => context.id).where("security_number & ?",User.account_readable_for_user).to_a.any?) || 
                (User.current.admin?))
                return true
              else
                return false
              end
            else
              false
            end
          end
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
          before_filter(:only => [:show]){ |controller| controller.require_user_security(params[:id]) }

          layout 'base'

          def update
            @user.admin = params[:user][:admin] if params[:user][:admin]
            @user.login = params[:user][:login] if params[:user][:login]
            @user.confirm = params[:user][:confirm] if params[:user][:confirm]
            if params[:user][:password].present? && (@user.auth_source_id.nil? || params[:user][:auth_source_id].blank?)
              @user.password, @user.password_confirmation = params[:user][:password], params[:user][:password_confirmation]
            end
            #should we do this here? 
            #@user.calc_security_number(params[:security])
            #

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

          def contact_member_search
            others = []
            if params[:q].nil? || params[:q]== '' || params[:q].split('').length < 3
              others = []
            else
              others = User.find(:all,
                :select => "firstname, lastname, id",
                :conditions => ['(lastname LIKE ? OR firstname LIKE ?) AND id <> ? AND security_number & ?',
                "#{params[:q]}%", "#{params[:q]}%", "#{User.current.id}",User.searchable_sql()],:limit => 5, :order => 'lastname')
            end

            if !(others.nil? || others.empty?)
              @projects = []
              @allusers = []
              @n_projects = {}

              project_list = Project.visible.find(:all, :order => 'lft')
              project_list.each do |project|
                n_users = {}
                user_projects = project.users_by_role
                user_projects.each do |user_project|
                  role = ""
                  user_project.each do |user_roles|
                    if user_roles.class.to_s == "Role"
                      role = user_roles.name
                    elsif user_roles.class.to_s == "Array"
                      user_roles.each do |user|
                        if !(others.detect {|v| v.id == user.id}).nil?
                          n_users[role] ||= []
                          n_users[role] << user
                          @allusers += [[user, role]]
                        end
                      end
                    end
                  end
                end
                if !n_users.empty? 
                  @n_projects[project.name] = n_users
                end
              end
              @allusers.sort! { |a,b| a[0].lastname.downcase <=> b[0].lastname.downcase }
              @n_projects[l(:no_common_project)] = {}
              @n_projects[l(:no_common_project)][""] = User.find((others - @allusers[0]).flatten.map{|m| m.id} )
            end

            respond_to do |format|
              format.js # user_search.js.erb
              format.json { render :json => @n_projects.to_json }
            end
          end

          def require_user_security(user_id)
            if((User.current.id.to_i == user_id.to_i) || 
              (User.where(:id => user_id).where("security_number & ?",User.account_readable_for_user).to_a.any?) || 
              (User.current.admin?))
              return true
            end
            return render_403
          end
        end
      end
    end
  end
