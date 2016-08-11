namespace :redmine do
  desc "purges user data of inactive users from the database"
  task :delete_inactive_user_data => :environment do
    User.warn_inactive_users_about_deletion
    User.delete_inactive_users
  end
end
