class AddFieldProjectAuthor < ActiveRecord::Migration
  def self.up
    add_column :projects, :author, :integer
  end

  def self.down
    remove_column :projects, :author
  end
end
