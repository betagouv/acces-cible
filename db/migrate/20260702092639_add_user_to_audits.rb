class AddUserToAudits < ActiveRecord::Migration[8.1]
  def change
    add_reference :audits, :user, null: true, foreign_key: true
  end
end
