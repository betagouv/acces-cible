class AddPriorityToChecks < ActiveRecord::Migration[8.0]
  def change
    add_column :checks, :priority, :integer, null: false, default: 100
  end
end
