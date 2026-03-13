class SetDefaultRunAtForChecks < ActiveRecord::Migration[8.0]
  def change
    change_column_default :checks, :run_at, from: nil, to: -> { "CURRENT_TIMESTAMP" }
    up_only do
      say_with_time "Set run_at = created_at" do
        Check.where(run_at: nil).update_all("run_at = created_at")
      end
    end
    change_column_null :checks, :run_at, true
  end
end
