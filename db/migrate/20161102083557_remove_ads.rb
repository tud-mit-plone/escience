class RemoveAds < ActiveRecord::Migration
  def up
    drop_table :ads
  end

  def down
    create_table "ads" do |t|
      t.string   "name"
      t.text     "html"
      t.integer  "frequency"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.datetime "start_date"
      t.datetime "end_date"
      t.string   "location"
      t.boolean  "published",        :default => false
      t.boolean  "time_constrained", :default => false
      t.string   "audience",         :default => "all"
    end
  end
end
