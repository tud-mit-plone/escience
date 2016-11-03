class RecreatePhotos < ActiveRecord::Migration
  def up
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
      t.integer  "comments_count"
      t.integer  "view_count"
      t.datetime "photo_updated_at"
    end
  end

  def down
    drop_table :photos
  end
end
