class FriendshipsController < ApplicationController
  before_filter :require_login, :except => [:accepted, :index]
  before_filter :find_user, :only => [:accepted, :pending, :denied]
  before_filter :require_current_user, :only => [:accept, :deny, :pending, :destroy]

  def index
    @body_class = 'friendships-browser'
    
    @user = User.current
    @friendships = Friendship.find(:all, :conditions => ['user_id = ? OR friend_id = ?', @user.id, @user.id], :limit => 40)
    @users = User.find(:all, :conditions => ['users.id in (?)', @friendships.collect{|f| f.friend_id }])    
    
    respond_to do |format|
      format.html 
      format.xml { render :action => 'index.rxml', :layout => false}    
    end
  end
  
  def deny
    @user = User.find(params[:user_id])    
    @friendship = @user.friendships.find(params[:id])
    
    respond_to do |format|
      if @friendship.update_attributes(:friendship_status => FriendshipStatus[:denied]) &&
         @friendship.reverse.update_attributes(:friendship_status => FriendshipStatus[:denied]) && 
         @friendship.reverse.save! && @friendship.save! 
        flash[:notice] = l(:the_friendship_was_denied)
        format.html { redirect_to denied_user_friendships_path(@user) }
      else
        format.html { redirect_to({ :action => "index"})}
      end
    end    
  end

  def accept
    @user = User.find(params[:user_id])    
    @friendship = @user.friendships_not_initiated_by_me.where(:id => params[:id]).first
     
    respond_to do |format|
      if @friendship.update_attributes(:friendship_status => FriendshipStatus[:accepted]) && 
          @friendship.reverse.update_attributes(:friendship_status => FriendshipStatus[:accepted])        
        flash[:notice] = :the_friendship_was_accepted
        format.html { redirect_to accepted_user_friendships_path(@user) }
      else
        format.html { redirect_to({ :action => "index"}) }
      end
    end
  end

  def denied
    @user = User.find(params[:user_id])    
    @friendships = @user.friendships.where("friendship_status_id = ?", FriendshipStatus[:denied].id).paginate(:page => params[:page])
    
    respond_to do |format|
      format.html
    end
  end

  def write_message
    @user_message = UserMessage.new
    @user_message_reply_mail = params[:reply]
    @user_message_reply = ""
    if !params[:id].nil?
      user = User.find(params[:id])
      if !user.nil?
        @user_message_reply_id = user.id
        @user_message_reply = " addUserToReceivers('#{user.firstname} #{user.lastname}', '#{user.id}');"
      end
    end
    respond_to do |format|
      format.html {render :partial => 'write_message'}
      format.js {render :partial => 'write_message'}
    end
  end

  def accepted
    @user = User.find(params[:user_id])    
    @friend_count = @user.accepted_friendships.count
    @pending_friendships_count = @user.pending_friendships.count

    @friendships = @user.friendships.accepted.paginate(:page => params[:page], :per_page => 20)
    
    respond_to do |format|
      format.html
    end
  end
  
  def pending
    @user = User.find(params[:user_id])

    @friendships = @user.friendships.where("initiator = ? AND friendship_status_id = ?", false, FriendshipStatus[:pending].id)
    @waiting_friendships = @user.friendships.where("initiator = ? AND friendship_status_id = ?", true, FriendshipStatus[:pending].id)
    respond_to do |format|
      format.html
    end
  end
  
  def show
    @friendship = Friendship.find(params[:id])
    @user = @friendship.user
    
    respond_to do |format|
      format.html
    end
  end
  

  def create
    @user = User.current
    @friendship = Friendship.new(:user_id => @user.id, :friend_id => params[:user_id], :initiator => true )
    @friendship.friendship_status_id = FriendshipStatus[:pending].id    
    reverse_friendship = Friendship.new(params[:friendship])
    reverse_friendship.friendship_status_id = FriendshipStatus[:pending].id 
    reverse_friendship.user_id, reverse_friendship.friend_id = @friendship.friend_id, @friendship.user_id
    
    respond_to do |format|
      if @friendship.save && reverse_friendship.save
        #UserNotifier.friendship_request(@friendship).deliver if @friendship.friend.notify_friend_requests?
        format.html {
          flash[:notice] = l(:friendship_requested, :friend => @friendship.friend.login.to_s) 
          redirect_to accepted_user_friendships_path(@user)
        }
        format.js { render( :inline => l(:requested_friendship_with) + " #{@friendship.friend.login}." ) }        
      else
        flash[:error] = l(:friendship_could_not_be_created)
        format.html { redirect_to user_friendships_path(@user) }
        format.js { render( :inline => "Friendship request failed." ) }                
      end
    end
  end
    
  def destroy
    if(User.current.id == params[:user_id] || User.current.admin?)

      @user = User.find(params[:user_id])    
      @friendship = Friendship.find(params[:id])
      Friendship.transaction do 
        @friendship.destroy
        @friendship.reverse.destroy
      end
      respond_to do |format|
        format.html { redirect_to accepted_user_friendships_path(@user) }
      end
    else
      back_to_where_you_came
    end
  end

  private 

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

    def back_to_where_you_came
      flash[:notice] ="#{l(:not_allowed)}"
      
      if request.referer.nil? 
        respond_to do |format| 
          format.html{ redirect_to :controller => "my"}
        end
      else
        respond_to do |format|
          format.html{ redirect_to request.referer }
        end
      end
    end
end