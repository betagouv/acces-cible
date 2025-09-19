class AllowNullDataOnChecks < ActiveRecord::Migration[8.0]
  def change
    change_column_null :checks, :data, true
    change_column_default :checks, :data, from: {}, to: nil
  end
end
