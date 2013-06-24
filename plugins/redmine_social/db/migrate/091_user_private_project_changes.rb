class UserPrivateProjectChanges < ActiveRecord::Migration
  def self.up
    add_column :users, :private_project_id, :integer 
    add_column :projects, :is_private_project, :boolean    
  end

  def self.down
    remove_column :users, :private_project_id
    remove_column :projects, :is_private_project
  end
end
