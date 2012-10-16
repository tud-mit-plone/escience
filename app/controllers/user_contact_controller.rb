class UserContactController < ApplicationController

  before_filter :require_login #, :only => [:index, :create, :update, :show, :sent_messages, :new, :destroy, :emptytrash, :edit, :archive]

  def index
    if User.current.anonymous?
      contacts = []
    else
      contacts = User.current.user_contacts.nil? ? [] : User.current.user_contacts
    end
    respond_to do |format|
      format.xml { render :xml => contacts }
      format.js { render :json => contacts }
      format.json { render :json => contacts }
    end
  end

  def add
    if User.current.id == params[:contact_member_id]
      return nil 
    end
    contacts = User.current.user_contacts
    new_contact = User.find(params[:contact_member_id])

    unless in_contact?(contacts,new_contact.id)
      uc = UserContact.new
      uc.user = User.current
      uc.contact_member = new_contact
      uc.save!
    end
    flash[:notice] = l(:notice_user_successful_added, :member => User.find(new_contact).to_s())
    redirect_to request.referrer
  end

  def delete
    unless User.current.anonymous?
      uc = UserContact.find_by_contact_member_id_and_user_id(params[:contact_member_id],User.current.id)
      uc.delete
    end
    flash[:notice] = l(:notice_user_successful_deleted, :member => User.find(params[:contact_member_id]).to_s())
    redirect_to request.referrer
  end

  private

  def in_contact?(contacts,id)
    contacts.each do |con|
      if con.contact_member_id == id
        return true
      end
    end
    return false 
  end

end
