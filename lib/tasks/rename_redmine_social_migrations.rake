namespace :redmine do
  desc "renames old redmine_social migrations now living in the core"
  task :rename_redmine_social_migrations => :environment do
    connection = ActiveRecord::Base.connection
    new_version_prefix = "20161024105024"
    rows = connection.execute("SELECT version FROM schema_migrations WHERE version LIKE '%-redmine_social'")
    rows.each do |row|
      old_version = row["version"]
      index = old_version.split("-")[0]
      new_version = new_version_prefix + index.to_s.rjust(3, "0")
      print "#{old_version} -> #{new_version}\n"
      connection.execute("UPDATE schema_migrations SET version = '#{new_version}' WHERE version = '#{old_version}'")
    end
  end
end
