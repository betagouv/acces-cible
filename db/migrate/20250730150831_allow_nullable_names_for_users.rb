class AllowNullableNamesForUsers < ActiveRecord::Migration[8.0]
  def change
    change_column_null :users, :given_name, true
    change_column_null :users, :usual_name, true
  end
end
