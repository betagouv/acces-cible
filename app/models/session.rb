class Session < ApplicationRecord
  MAX_IDLE_TIME = 7.days
  MAX_LIFETIME = 1.month

  belongs_to :user, touch: true

  scope :active, -> { where(updated_at: MAX_IDLE_TIME.ago.., created_at: MAX_LIFETIME.ago..) }
  scope :expired, -> { where(updated_at: ...MAX_IDLE_TIME.ago).or(where(created_at: ...MAX_LIFETIME.ago)) }

  def should_touch?
    updated_at.before?(1.day.ago)
  end
end
