class UpdateFailedTransitionsWithMetadataToErrored < ActiveRecord::Migration[8.0]
  def up
    say_with_time "Change failed CheckTransition to errored state when there is error data" do
      CheckTransition.where(to_state: :failed)
                    .where("metadata IS NOT NULL AND metadata::text != '{}'")
                    .update_all(to_state: :errored)
    end
  end

  def down
    say_with_time "Revert errored CheckTransition back to failed state" do
      CheckTransition.where(to_state: :errored)
                    .where("metadata IS NOT NULL AND metadata::text != '{}'")
                    .update_all(to_state: :failed)
    end
  end
end
