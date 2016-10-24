class AddAlbumIdToPhotos < ActiveRecord::Migration
  def self.up
    add_column :photos, :album_id, :integer
    add_column :photos, :comments_count, :integer
  end

  def self.down
    remove_column :photos, :album_id
    remove_column :photos, :comments_count
  end
end
