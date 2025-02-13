class CreateSites < ActiveRecord::Migration[8.0]
  def change
    create_table :sites do |t|
      t.string :name
      t.string :slug, null: false

      t.timestamps

      t.index :slug, unique: true
    end
  end
end
