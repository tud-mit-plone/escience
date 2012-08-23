class AddTaggerAndContext < ActiveRecord::Migration
  require_dependency 'acts_as_taggable_on/tagging'

  def self.up
    add_column :taggings, :context, :string
    add_column :taggings, :tagger_id, :integer
    add_column :taggings, :tagger_type, :string

    add_index :taggings, [:taggable_id, :taggable_type, :context]

    ActsAsTaggableOn::Tagging.update_all("context = 'tags'", "context = NULL")
  end

  def self.down
    remove_column :taggings, :context
    remove_column :taggings, :tagger_id
    remove_column :taggings, :tagger_type
  end
end
