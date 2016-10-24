class AddViewCountToAlbums < ActiveRecord::Migration
  def self.up
    add_column :albums, :view_count, :integer
    add_column :albums, :comments_count, :integer
  end

  def self.down
    remove_column :albums, :view_count
    remove_column :albums, :comments_count
  end
end
