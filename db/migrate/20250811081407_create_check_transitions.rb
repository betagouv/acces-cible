class CreateCheckTransitions < ActiveRecord::Migration[8.0]
  def change
    create_table :check_transitions do |t|
      t.string :to_state, null: false
      t.json :metadata, default: {}
      t.integer :sort_key, null: false
      t.integer :check_id, null: false
      t.boolean :most_recent, null: false

      t.timestamps null: false
    end

    # Foreign keys are optional, but highly recommended
    add_foreign_key :check_transitions, :checks

    add_index(:check_transitions,
              %i(check_id sort_key),
              unique: true,
              name: "index_check_transitions_parent_sort")
    add_index(:check_transitions,
              %i(check_id most_recent),
              unique: true,
              where: "most_recent",
              name: "index_check_transitions_parent_most_recent")
  end
end
