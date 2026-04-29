class CheckTransition < ApplicationRecord
  belongs_to :check, inverse_of: :check_transitions

  validates :to_state, inclusion: { in: CheckStateMachine.states }

  after_destroy :update_most_recent, if: :most_recent?

  private

  def update_most_recent
    last_transition = check.check_transitions.order(:sort_key).last
    return unless last_transition.present?
    last_transition.update_column(:most_recent, true)
  end
end
