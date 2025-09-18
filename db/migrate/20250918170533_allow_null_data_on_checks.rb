class AllowNullDataOnChecks < ActiveRecord::Migration[8.0]
  def change
    change_column_null :checks, :data, true
    change_column_default :checks, :data, from: {}, to: nil

    say_with_time "Updating checks.data default value" do
      if reverting?
        Check.where(data: nil).update_all(data: {})
      else
        Check.where(data: {}).update_all(data: nil)
      end
    end
  end
end
