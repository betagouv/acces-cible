class User < ApplicationRecord
  belongs_to :team, foreign_key: :siret, primary_key: :siret, inverse_of: :users
  has_many :sessions, dependent: :destroy

  validates :provider, :uid, :email, :given_name, :usual_name, :siret, presence: true
  validates :uid, uniqueness: { scope: :provider, if: :uid_changed? }
  validates :email, uniqueness: true, if: :email_changed?
  validates :email, email: true

  normalizes :email, with: ->(value) { value.strip.downcase }
  normalizes :siret, with: ->(value) { value.to_s.gsub(/[^a-zA-Z0-9]/, "") }

  before_validation :find_or_create_team, on: :create

  class << self
    def from_omniauth(auth)
      find_or_create_by(provider: auth.provider, uid: auth.uid) do |user|
        user.email = auth.info.email
        user.siret = auth.info.siret
        user.given_name = auth.info.given_name
        user.usual_name = auth.info.usual_name
      end
    end
  end

  private

  def find_or_create_team
    self.team ||= Team.find_or_create_by(siret:)
  end
end
