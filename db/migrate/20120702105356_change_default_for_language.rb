class ChangeDefaultForLanguage < ActiveRecord::Migration
  def self.up
    if !(ActiveRecord::Base.connection.instance_values["config"][:adapter].include?("sqlite"))
      execute "ALTER TABLE users ALTER language SET DEFAULT 'de';"
      #change_table :users do |t|
      #  t.change :language, :null => false, :default => 'de'
      #end
    end
  end

  def self.down
    if !(ActiveRecord::Base.connection.instance_values["config"][:adapter].include?("sqlite"))
      execute "ALTER TABLE users ALTER language SET DEFAULT '';"
    end
  end
end
