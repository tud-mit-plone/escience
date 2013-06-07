class FriendshipsController < ApplicationSocialController
  unloadable
  before_filter :require_login, :except => [:accepted, :index]
  before_filter :find_user, :only => [:accepted, :pending, :denied, :index]
  before_filter :require_current_user, :only => [:accept, :deny, :pending, :destroy]

  def index
    @user = User.find(params[:user_id])    
    @friend_count = @user.accepted_friendships.count
    @pending_friendships_count = @user.pending_friendships.count
    @friendships = @user.friendships.accepted
    @waiting_friendships = @user.friendships.where("initiator = ? AND friendship_status_id = ?", false, FriendshipStatus[:pending].id)
    
    respond_to do |format|
      format.html
    end
  end
  
  def deny
    @user = User.find(params[:user_id])    
    @friend_count = @user.accepted_friendships.count
    @pending_friendships_count = @user.pending_friendships.count
    @friendships = @user.friendships.accepted
    @friendship = @user.friendships.find(params[:id])
    @waiting_friendships = @user.friendships.where("initiator = ? AND friendship_status_id = ?", false, FriendshipStatus[:pending].id)
    
    respond_to do |format|
      if @friendship.update_attributes(:friendship_status => FriendshipStatus[:denied]) &&
         @friendship.reverse.update_attributes(:friendship_status => FriendshipStatus[:denied]) && 
         @friendship.reverse.save! && @friendship.save! 
        flash[:notice] = l(:the_friendship_was_denied)
        format.html { 
            if @waiting_friendships.count > 0 
              redirect_to({:action => "index", :tab => 'pending'}) 
            else
              redirect_to({:action => "index"})
            end
        }
        format.js {
          render :partial => 'update'
        }
      else
        format.html { redirect_to({ :action => "index"})}
      end
    end    
  end

  def accept
    @user = User.find(params[:user_id])    
    @friend_count = @user.accepted_friendships.count
    @pending_friendships_count = @user.pending_friendships.count
    @friendships = @user.friendships.accepted
    @friendship = @user.friendships_not_initiated_by_me.where(:id => params[:id]).first
    @waiting_friendships = @user.friendships.where("initiator = ? AND friendship_status_id = ?", false, FriendshipStatus[:pending].id)
    respond_to do |format|
      if @friendship.update_attributes(:friendship_status => FriendshipStatus[:accepted]) && 
          @friendship.reverse.update_attributes(:friendship_status => FriendshipStatus[:accepted])        
        flash[:notice] = l(:the_friendship_was_accepted)
        format.html { 
            if @waiting_friendships.count > 0 
              redirect_to({:action => "index", :tab => 'pending'}) 
            else
              redirect_to({:action => "index"})
            end
        }
        format.js {
          render :partial => 'update'
        }
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
    @friendships = @user.friendships.accepted
    
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
    @friendship = User.current.friendships.where("user_id = ? AND friend_id = ?", params[:user_id], params[:id]).first    
    respond_to do |format|
      format.html {
#        render :partial => "users/show",:locals => {:user => @friendship.user, :memberships => @friendship.user.memberships.all(:conditions => Project.visible_condition(@friendship.user))}
        render :partial => "friendships/friendship", :locals => {:friendship => @friendship}
      }
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
        flash[:notice] = l(:friendship_requested, :friend => @friendship.friend) 
        @friend_count = @user.accepted_friendships.count
        @pending_friendships_count = @user.pending_friendships.count
        @friendships = @user.friendships.accepted
        @friendship = @user.friendships_not_initiated_by_me.where(:id => params[:id]).first
        @waiting_friendships = @user.friendships.where("initiator = ? AND friendship_status_id = ?", false, FriendshipStatus[:pending].id)
        format.html {
          redirect_to accepted_user_friendships_path(@user)
        }
        format.js { render :partial => 'update' }        
      else
        flash[:error] = l(:friendship_could_not_be_created)
        format.html { redirect_to user_friendships_path(@user) }
        format.js { render( :inline => "Friendship request failed." ) }                
      end
    end
  end
    
  def destroy
    if(User.current.id.to_s == params[:user_id] || User.current.admin?)

      @user = User.find(params[:user_id])    
      @friendship = Friendship.find(params[:id])
      Friendship.transaction do 
        @friendship.destroy
        @friendship.reverse.destroy
      end
      @friend_count = @user.accepted_friendships.count
      @pending_friendships_count = @user.pending_friendships.count
      @friendships = @user.friendships.accepted
      @friendship = @user.friendships_not_initiated_by_me.where(:id => params[:id]).first
      @waiting_friendships = @user.friendships.where("initiator = ? AND friendship_status_id = ?", false, FriendshipStatus[:pending].id)
      respond_to do |format|
        flash[:notice] ="#{l(:deleted_this_user)}"
        format.html { redirect_to accepted_user_friendships_path(@user) }
        format.js { render :partial => 'update' }
      end
    else
      back_to_where_you_came
    end
  end

  private 
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