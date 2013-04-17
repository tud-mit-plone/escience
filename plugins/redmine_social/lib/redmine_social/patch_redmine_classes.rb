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
        
        def can_request_friendship_with(user)
          !self.eql?(user) && !self.friendship_exists_with?(user)
        end

        def friendship_exists_with?(friend)
          Friendship.find(:first, :conditions => ["user_id = ? AND friend_id = ?", self.id, friend.id])
        end

        def has_reached_daily_friend_request_limit?
          friendships_initiated_by_me.count(:conditions => ['created_on > ?', Time.now.beginning_of_day]) >= Friendship.daily_request_limit
        end
      end
      
      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          #avatar
          belongs_to  :avatar, :class_name => "Photo", :foreign_key => "avatar_id", :inverse_of => :user_as_avatar
          #friendship associations
          has_many :friendships, :class_name => "Friendship", :foreign_key => "user_id", :dependent => :destroy
          has_many :accepted_friendships, :class_name => "Friendship", :conditions => ['friendship_status_id = ?', 2]
          has_many :pending_friendships, :class_name => "Friendship", :conditions => ['initiator = ? AND friendship_status_id = ?', false, 1]
          has_many :friendships_initiated_by_me, :class_name => "Friendship", :foreign_key => "user_id", :conditions => ['initiator = ?', true], :dependent => :destroy
          has_many :friendships_not_initiated_by_me, :class_name => "Friendship", :foreign_key => "user_id", :conditions => ['initiator = ?', false], :dependent => :destroy
          has_many :occurances_as_friend, :class_name => "Friendship", :foreign_key => "friend_id", :dependent => :destroy
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
          return unless request.put?

          @avatar.name = params[:photo][:filename] 
          @avatar.user  = @user
          if @avatar.save
            @user.avatar_id  = @avatar.id
            @user.save!
            redirect_to crop_profile_photo_user_path(@user)
          end
        end
        
        def crop_profile_photo
          @user = User.find(params[:id])
           unless @photo = @user.avatar
             flash[:notice] = l(:no_profile_photo)
             redirect_to upload_profile_photo_user_path(@user) and return
           end
           return unless request.put?
           logger.info(":crop_x =>#{ params[:photo][:crop_x]}, :crop_y => #{params[:photo][:crop_y]}, :crop_w => #{params[:photo][:crop_w]}, :crop_h => #{params[:photo][:crop_h]}")
           @photo.update_attributes(:crop_x => params[:photo][:crop_x], 
                                                      :crop_y => params[:photo][:crop_y], 
                                                      :crop_w => params[:photo][:crop_w], 
                                                      :crop_h => params[:photo][:crop_h])
           redirect_to user_path(@user)
         end
      end
      
      def self.included(receiver)
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
        receiver.class_eval do
          before_filter :require_admin, :except => [:show, :user_search, :contact_member_search, :online_live_count, :crop_profile_photo, :upload_profile_photo]
          layout 'base'
        end
      end
    end
  end