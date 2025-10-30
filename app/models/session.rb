class Session < ApplicationRecord
  MAX_IDLE_TIME = 1.month

  belongs_to :user, touch: true

  scope :active, -> { where(updated_at: MAX_IDLE_TIME.ago..) }
  scope :inactive, -> { where(updated_at: ...MAX_IDLE_TIME.ago) }

  def should_touch? = updated_at.before?(1.day.ago)
end
