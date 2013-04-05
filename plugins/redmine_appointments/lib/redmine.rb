Redmine::AccessControl.map do |map|
  map.permission :add_project, {:projects => [:new, :create]}, :require => :loggedin
end