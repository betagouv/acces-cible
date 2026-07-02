class AddNotNullConstraintToAuditsUserId < ActiveRecord::Migration[8.1]
  def change
    change_column_null :audits, :user_id, false
  end
end
