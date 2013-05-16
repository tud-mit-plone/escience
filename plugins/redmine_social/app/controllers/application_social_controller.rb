class ApplicationSocialController < ApplicationController
  unloadable
  def find_user
      @user = User.current
      unless @user.anonymous?
        @is_current_user = (@user && @user.eql?(User.current))
        unless User.current.logged? || @user.profile_public?
          flash[:error] = l(:private_user_profile_message)
          access_denied 
        else
          return @user
        end
      else
        flash[:error] = l(:please_log_in)
        redirect_to :controller => "welcome", :action => "index", :back_url => url_for(params)
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