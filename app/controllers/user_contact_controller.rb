class UserContactController < ApplicationController

  before_filter :require_login #, :only => [:index, :create, :update, :show, :sent_messages, :new, :destroy, :emptytrash, :edit, :archive]

  def index
    if User.current.anonymous?
      contacts = []
    else
      contacts = User.current.user_contacts.nil? ? [] : User.current.user_contacts
    end
    contact_users = []
    contacts.each do |con|
      u = User.find(con.contact_member)
      contact_users << "#{u.firstname}, #{u.lastname}"
    end
    respond_to do |format|
      format.xml { render :xml => contact_users }
      format.js { render :json => contact_users }
      format.json { render :json => contact_users }
    end
  end

  def add
    if params[:contact_member_id].nil? || User.current.id == params[:contact_member_id]
      return nil 
    end
    new_contact = User.find(params[:contact_member_id])

    if UserContact.find_by_user_id_and_contact_member_id(User.current.id,new_contact).nil?
      uc = UserContact.new
      uc.user = User.current
      uc.contact_member = new_contact
      uc.save!
    end
    flash[:notice] = l(:notice_user_successful_added, :member => User.find(new_contact).to_s())

    unless request.referrer.nil?
      redirect_to request.referrer
    else
      redirect_to(:controller => 'my', :action => :members)
    end
  end

  def delete
    unless User.current.anonymous?
      uc = UserContact.find_by_contact_member_id_and_user_id(params[:contact_member_id],User.current.id)
      uc.delete
    end
    flash[:notice] = l(:notice_user_successful_deleted, :member => User.find(params[:contact_member_id]).to_s())
    unless request.referrer.nil?
      redirect_to request.referrer
    else
      redirect_to(:controller => 'my', :action => :members)
    end
  end

end
