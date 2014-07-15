module UserMessagesHelper

  def add_user_to_receivers(user)
    return javascript_tag("jQuery(document).ready( function() {addUserToReceivers('#{user.firstname} #{user.lastname}', '#{user.id}');});")
  end
end
