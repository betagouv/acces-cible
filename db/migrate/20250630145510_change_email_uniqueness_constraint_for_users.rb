class ChangeEmailUniquenessConstraintForUsers < ActiveRecord::Migration[8.0]
  def up
    remove_index :users, :email, unique: true
  end

  def down
    add_index :users, [:email, :provider], unique: true
  end
end
