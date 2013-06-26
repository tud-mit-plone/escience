class ChangeSizeForDepartment < ActiveRecord::Migration
  def self.up
    change_column('users','department', :string, :limit => 256) 
  end

  def self.down
    change_column('users','department', :string, :limit => 30)
  end
end
