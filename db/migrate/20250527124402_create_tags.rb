class CreateTags < ActiveRecord::Migration[8.0]
  def change
    create_table :tags do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.belongs_to :team, null: false, foreign_key: true

      t.timestamps

      t.index [:name, :team_id], unique: true
      t.index [:slug, :team_id], unique: true
    end

    create_table :site_tags do |t|
      t.belongs_to :site, null: false, foreign_key: true
      t.belongs_to :tag, null: false, foreign_key: true

      t.index [:site_id, :tag_id], unique: true
    end
  end
end
