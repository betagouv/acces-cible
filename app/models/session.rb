class Session < ApplicationRecord
  MAX_IDLE_TIME = 1.month

  belongs_to :user, touch: true

  scope :active, -> { where(updated_at: MAX_IDLE_TIME.ago..) }
end
