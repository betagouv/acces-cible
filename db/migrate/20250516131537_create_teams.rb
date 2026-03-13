class CreateTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :teams do |t|
      t.string :siret, null: false
      t.string :organizational_unit
      t.string :name

      t.timestamps

      t.index :siret, unique: true
    end

    add_foreign_key :users, :teams, column: :siret, primary_key: :siret, name: :fk_users_on_team_siret
  end
end
