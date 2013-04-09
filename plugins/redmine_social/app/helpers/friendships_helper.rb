module FriendshipsHelper

  def friendship_control_links(friendship)
    html = case friendship.friendship_status_id
      when FriendshipStatus[:pending].id
        "#{(link_to( l(:accept), accept_user_friendship_path(friendship.user, friendship), :method => :put, :class => 'button positive') unless friendship.initiator?)} #{link_to(l(:deny), deny_user_friendship_path(friendship.user, friendship), :method => :put, :class => 'button negative')}"
      when FriendshipStatus[:accepted].id
        "#{link_to(l(:remove_this_friend), deny_user_friendship_path(friendship.user, friendship), :method => :put, :class => 'button negative')}"
      when FriendshipStatus[:denied].id 
        if(friendship.initiator == true and (friendship.user == User.current || User.current.admin?))
          "#{link_to(l(:delete_this_request), user_friendship_path(User.current,friendship), 
            :method => :delete, :confirm => l(:are_you_sure), :class => 'button negative')}"
        else
          "#{link_to(l(:accept_this_request), accept_user_friendship_path(friendship.user, friendship), :method => :put, :class => 'button positive')}"
        end
    end
    
    html.html_safe
  end
end
