class UserSecurityChanges< ActiveRecord::Migration
  def self.up
    add_column  :users, :security_number, :integer, :default => 0, :null => true
  end

  def self.down
    remove_column :users, :security_number
  end
end