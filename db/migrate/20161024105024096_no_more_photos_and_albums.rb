class NoMorePhotosAndAlbums < ActiveRecord::Migration
  def up
    drop_table :albums
    drop_table :photos
  end

  def down
    create_table "photos", :force => true do |t|
      t.string   "name"
      t.text     "description"
      t.datetime "created_at",         :null => false
      t.datetime "updated_at",         :null => false
      t.integer  "user_id"
      t.string   "photo_content_type"
      t.string   "photo_file_name"
      t.integer  "photo_file_size"
      t.integer  "parent_id"
      t.string   "thumbnail"
      t.integer  "width"
      t.integer  "height"
      t.integer  "album_id"
      t.integer  "comments_count"
      t.integer  "view_count"
      t.datetime "photo_updated_at"
    end
    create_table "albums"  do |t|
      t.string   "title"
      t.text     "description"
      t.integer  "user_id"
      t.datetime "created_at",     :null => false
      t.datetime "updated_at",     :null => false
      t.integer  "view_count"
      t.integer  "comments_count"
      t.integer  "container_id"
      t.string   "container_type"
    end
  end
end
