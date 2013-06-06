class GroupInvitationsController < ApplicationSocialController
  unloadable

   before_filter :require_login
   before_filter :get_user
   before_filter :get_model_for_invitation, :only => [:create]
   before_filter :get_group_invitation, :except => [:create]
   before_filter :require_receiver_user, :only => [:selection]
   before_filter :authorized, :only => [:create]
#   before_filter :user_already_in_group?, :only => [:create]

  #Todo create permission to role for inviting people to groups etc. 
  def create
    sender_u_msg = UserMessage.new({ :body => "Wie sieht's aus?",
                                                                 :subject => "kommste mit?",
                                                                 :user => User.current,
                                                                 :author => User.current,
                                                                 :receiver_id => params[:receiver_id],
                                                                 :state => 3,
                                                                 :directory => UserMessage.sent_directory})
    if sender_u_msg.save 
      receiver_u_msg = sender_u_msg.generate_sent_receiver_copy()
#      receiver_u_msg.save
    else 
      render_404
    end
    
    inv = GroupInvitation.new()
    inv.user_messages << sender_u_msg
    inv.user_messages << receiver_u_msg
    
    inv.group = @model 
    inv.friendship_status_id = FriendshipStatus.where(:name => "pending").first.id
    
    unless inv.save
      receiver_u_msg.destroy
      sender_u_msg.destroy
    end

    logger.info inv.errors.full_messages
    flash[:notice] = inv.errors.full_messages 
#    redirect_to :controller =>  @model_name.pluralize
  
    respond_to do |format|
      flash[:notice] = :the_friendship_was_accepted
      format.html { redirect_to :controller =>  @model_name.pluralize }
      format.js {
        render :js => "$.notification({ message:'Es funktioniert', type:'error' })";
      }
#      format.js { render :js => "alert('geiler scheiß')" }
    end
    
  end  

  def selection 
    unless params[:true].nil?
      @group_invitation.friendship_status_id = FriendshipStatus[:accepted].id
      m = Member.new(:user_id => @user.id, :project => @group_invitation.group, :role_ids => [Setting.plugin_redmine_social[:invitation_default_role_id]])
      m.save!
      @group_invitation.group.members << m
      @group_invitation.save!
      flash[:notice] = "You accepted" 
    else 
      @group_invitation.friendship_status_id = FriendshipStatus[:denied].id
      @group_invitation.save!
      flash[:notice] = "You denied!"   
    end
    redirect_to request.referer   
  end

  private 

  def require_receiver_user
    unless (User.current != @group_invitation.user_messages.where(:state => [0,1]).first.author || User.current.admin?) 
      render_403
    end
  end

  def get_group_invitation
    @group_invitation = GroupInvitation.find(params[:id])
  end

  def get_model_for_invitation
    GroupInvitation.get_invitation_group.each do |m_name|
      next if m_name.nil? 
      id= "#{m_name.downcase.singularize}_id"
      
      next if params[id.to_sym].nil?
      @model = m_name.constantize.find(params[id.to_sym])
      @model_name = m_name.downcase.singularize
      return
    end
  end

  #some more alteration in User.allowed_to? necessary for supporting more than projects as models 
  def authorized 
    if @model.nil? 
      get_model_for_invitation
    end
    unless @user.allowed_to?({:controller => 'members', :action => 'create'}, @model)
      render_403
    end
  end

  def get_user
    if params[:user_id]
      @user = User.find(params[:user_id])
    else 
      @user = User.current
    end
  end
end