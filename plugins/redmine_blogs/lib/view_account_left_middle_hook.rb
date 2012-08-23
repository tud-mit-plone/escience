module RedmineBlogs
  class ViewAccountLeftMiddleHook < Redmine::Hook::ViewListener
    def view_account_left_middle(context={})
      if User.current.allowed_to?(:view_blogs, @project, {:global => true})
        user = context[:user]
        @blogs = Blog.all(:limit => 5,
                          :order => "#{Blog.table_name}.created_on DESC",
                          :conditions => ["author_id = ? and project_id = ?", user.id, @project.id])

        return context[:controller].send(:render_to_string, {
                                         :partial => 'blogs/user_page',
                                         :locals => {:blogs => @blogs, :user => user, :project_id => @project}})
      else
        return ""
      end

    end
  end
end
