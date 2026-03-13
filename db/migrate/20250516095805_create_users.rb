class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :provider, null: false
      t.string :uid, null: false
      t.string :email, null: false
      t.string :given_name, null: false
      t.string :usual_name, null: false
      t.string :siret, null: false

      t.timestamps

      t.index :siret
      t.index :email, unique: true
      t.index [:provider, :uid], unique: true
    end
  end
end
