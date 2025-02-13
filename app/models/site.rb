class Site < ApplicationRecord
  extend FriendlyId

  friendly_id :url, use: [:slugged, :history]

  attribute :url, :string
end
