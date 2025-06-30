class Team < ApplicationRecord
  has_many :users, foreign_key: :siret, primary_key: :siret, inverse_of: :team, dependent: :destroy
  has_many :sites, dependent: :destroy
  has_many :tags, -> { in_alphabetical_order }, dependent: :destroy

  validates :siret, presence: true, uniqueness: true

  normalizes :siret, with: ->(value) { value.to_s.gsub(/\D/, "") }
end
