class AddCreatorToProjects < ActiveRecord::Migration
  def change
    add_column :projects, :creator, :Integer
  end
end
