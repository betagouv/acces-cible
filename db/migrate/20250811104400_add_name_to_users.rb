class AddNameToUsers < ActiveRecord::Migration[8.0]

  class User < ActiveRecord::Base
    self.table_name = 'users'
  end

  def up
    add_column :users, :name, :string

    User.find_each do |user|
      name = [user.given_name, user.usual_name].compact.join(" ")
      user.update(name: name)
    end

    change_column_null :users, :name, false
  end

  def down
    User.find_each do |user|
      given_name, usual_name = user.name.split(" ")
      user.update(given_name: given_name, usual_name: usual_name)
    end

    remove_column :users, :name
  end
end
