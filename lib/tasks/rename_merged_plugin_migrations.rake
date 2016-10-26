namespace :redmine do
  desc "renames old redmine_social migrations now living in the core"
  task :rename_merged_plugin_migrations => :environment do
    connection = ActiveRecord::Base.connection
    new_version_prefixes = {
      "redmine_social" => "20161024105024",
      "redmine_appointments" => "20161026095742",
      "redmine_doodles" => "20161026150841",
    }
    new_version_prefixes.each do |plugin_name, new_version_prefix|
      rows = connection.exec_query("SELECT version FROM schema_migrations WHERE version LIKE '%-#{plugin_name}'")
      rows.each do |row|
        old_version = row["version"]
        index = old_version.split("-")[0]
        new_version = new_version_prefix + index.to_s.rjust(3, "0")
        print "#{old_version} -> #{new_version}\n"
        connection.exec_update("UPDATE schema_migrations SET version = '#{new_version}' WHERE version = '#{old_version}'", "update schema migration version", [])
      end
    end
  end
end
