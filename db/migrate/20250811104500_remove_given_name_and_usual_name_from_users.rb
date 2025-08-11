class RemoveGivenNameAndUsualNameFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :given_name, :string
    remove_column :users, :usual_name, :string
  end
end
