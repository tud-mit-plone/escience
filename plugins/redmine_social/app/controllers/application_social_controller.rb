class ApplicationSocialController < ApplicationController
  unloadable
  def find_user
      if @user = User.active.find(params[:user_id] || params[:id])
        @is_current_user = (@user && @user.eql?(User.current))
        unless User.current.logged? || @user.profile_public?
          flash[:error] = :private_user_profile_message.l
          access_denied 
        else
          return @user
        end
      else
        flash[:error] = :please_log_in.l
        access_denied
      end
    end
  
    def require_current_user
      @user ||= User.find(params[:user_id] || params[:id] )
      unless User.current.admin? || (@user && (@user.eql?(User.current)))
        back_to_where_you_came and return false
      end
      return @user
    end
end