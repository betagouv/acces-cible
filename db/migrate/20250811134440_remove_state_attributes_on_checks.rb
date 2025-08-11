class RemoveStateAttributesOnChecks < ActiveRecord::Migration[8.0]
  # Checks now use a state machine with a dedicated transition model
  # (CheckTransition) that offers timestamps, latest_state &
  # metadata, removing the need to store retry_at/checked_at
  # (transitions have timestamps) or error status (which now belongs
  # in the `failed' transition's metadata)
  def change
    remove_index  :checks, column: [:status, :run_at]

    remove_column :checks, :run_at, :datetime
    remove_column :checks, :status, :string, null: false
    remove_column :checks, :checked_at, :datetime
    remove_column :checks, :retry_at, :datetime

    remove_column :checks, :error_type, :string
    remove_column :checks, :error_message, :text
    remove_column :checks, :error_backtrace, :string
  end
end
