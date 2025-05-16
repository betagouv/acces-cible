class Team < ApplicationRecord
  has_many :users, foreign_key: :siret, primary_key: :siret, inverse_of: :team

  validates :siret, presence: true, uniqueness: true
end
