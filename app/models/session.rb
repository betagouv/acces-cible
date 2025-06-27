class Session < ApplicationRecord
  belongs_to :user, touch: true
end
