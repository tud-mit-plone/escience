class NoMoreUserPrivateProject < ActiveRecord::Migration
  def up
    remove_column :users, :private_project_id
    remove_column :projects, :is_private_project
  end

  def down
    add_column :users, :private_project_id, :integer
    add_column :projects, :is_private_project, :boolean
  end
end
