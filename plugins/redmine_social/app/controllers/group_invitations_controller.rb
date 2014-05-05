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
    if params[:controller_name].nil? 
      send_single_invitation
    elsif params[:controller_name].downcase.singularize == 'project' && !(params[:id].nil?)
      send_members_invitations(params[:membership][:user_ids],params[:membership][:role_ids])
    else 
      render_404
    end
  end  

  def selection 
    unless params[:true].nil?
      @group_invitation.friendship_status_id = FriendshipStatus[:accepted].id

      @group_invitation.role_ids = [@group_invitation.role_ids] if !(@group_invitation.role_ids.class == Array)
      roles =  @group_invitation.role_ids.any? ? @group_invitation.role_ids : [Setting.plugin_redmine_social['invitation_default_role_id']]
      
      m = Member.new(:user_id => @user.id, :project => @group_invitation.group, :role_ids => roles)
      if(m.save)
        @group_invitation.group.members << m
        @group_invitation.save!
        flash[:notice] = l(:project_invitation_accepted, project: group_invitation.group.name)
      else
        flash[:error] = "Member not created"
      end
    else 
      @group_invitation.friendship_status_id = FriendshipStatus[:denied].id
      @group_invitation.save!
      flash[:notice] = l(:project_invitation_denied)
    end
    respond_to do |format|
      format.html {render :partial => 'update'}
      format.js {render :partial => 'update'}
    end
#    redirect_to request.referer   
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
      
      if(!(params[id.to_sym].nil?))
        @model = m_name.constantize.find(params[id.to_sym])
        @model_name = m_name.downcase.singularize
        return
      elsif(params[:id] && params[:controller_name].to_s.downcase.singularize == m_name.downcase.singularize)
        @model = m_name.constantize.find(params[:id])
        @model_name = m_name.downcase.singularize
        return
      else
        next
      end
    end
  end

  #some more alteration in User.allowed_to? necessary for supporting more than projects as models 
  def authorized 
    if @model.nil? 
      get_model_for_invitation
    end
    unless @user.allowed_to?({:controller => params[:controller], :action => params[:action]}, @model)
      render_403({:message => ":controller => :members, :action => :create, :user => #{@user}, :from => #{params[:controller]}\##{params[:action]}"})
    end
  end

  def user_already_in_group?
    raise 
  end

  def get_user
    if params[:user_id]
      @user = User.find(params[:user_id])
    else 
      @user = User.current
    end
    return @user
  end

  def send_members_invitations(new_members,roles) 
    if !(new_members.class == Array)
      new_members = [new_members]
    end

    errors ||= []
    notices ||= []
    
    new_members.each do |recv|
      sender_u_msg, receiver_u_msg = create_invitation_messages({:project_id => params[:id], :receiver_id => recv })
      if sender_u_msg.nil? || receiver_u_msg.nil? 
        errors << recv
        next
      end
            
      inv = create_group_invitation(sender_u_msg, receiver_u_msg,roles)
      logger.info inv.errors.full_messages
      notices << inv.errors.full_messages 
    end
    
    logger.info errors.join("\n")

    flash[:notice] = notices.join("\n")
  
    respond_to do |format|
      flash[:notice] = :project_invitation_sent
      format.html { redirect_to :controller =>  @model_name.pluralize }
      format.js {
        render :js => "$.notification({ message:'"+l(:project_invitation_sent)+"', type:'notice' })";
      }
    end
  end

  def send_single_invitation 
    sender_u_msg, receiver_u_msg = create_invitation_messages

    if sender_u_msg.nil? || receiver_u_msg.nil? 
      render_404
    end

    inv = create_group_invitation(sender_u_msg, receiver_u_msg)

    logger.info inv.errors.full_messages
    flash[:notice] = inv.errors.full_messages 
#    redirect_to :controller =>  @model_name.pluralize
  
    respond_to do |format|
      flash[:notice] = :project_invitation_sent
      format.html { redirect_to :controller =>  @model_name.pluralize }
      format.js {
        render :js => "$.notification({ message:'"+l(:project_invitation_sent)+"', type:'notice' })";
      }
    end
  end

  def create_group_invitation(sender_u_msg, receiver_u_msg,roles)
    inv = GroupInvitation.new()
    inv.user_messages << sender_u_msg
    inv.user_messages << receiver_u_msg
    
    inv.group = @model 
    inv.friendship_status_id = FriendshipStatus.where(:name => "pending").first.id
    inv.role_ids = roles

    unless inv.save
      receiver_u_msg.destroy
      sender_u_msg.destroy
    end

    return inv
  end

  def create_invitation_messages(options = {})
    if options.class == Hash && !options.empty?
      project_id = options[:project_id] ? options[:project_id] : params[:project_id]
      receiver_id = options[:receiver_id] ? options[:receiver_id] : params[:receiver_id]
    else
      project_id = params[:project_id]
      receiver_id = options[:receiver_id]
    end

    sender_u_msg = UserMessage.new({ :body => l(:invitation_for_project_message,:project => Project.find(project_id)),
                                                             :subject => l(:invitation_for_project_subject),
                                                             :user => User.current,
                                                             :author => User.current,
                                                             :receiver_id => receiver_id,
                                                             :state => 3,
                                                             :directory => UserMessage.sent_directory})
    if sender_u_msg.save 
      receiver_u_msg = sender_u_msg.generate_sent_receiver_copy()
      receiver_u_msg = nil unless receiver_u_msg.save
    else
      sender_u_msg = nil 
    end 

    return sender_u_msg,receiver_u_msg
  end
end