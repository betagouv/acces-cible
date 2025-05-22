class CreateSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :sessions do |t|
      t.belongs_to :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
