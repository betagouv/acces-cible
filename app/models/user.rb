class User < ApplicationRecord
  include Privileged

  MAX_IDLE_TIME = 1.year

  belongs_to :team, foreign_key: :siret, primary_key: :siret, inverse_of: :users, touch: true
  has_many :sites, through: :team
  has_many :sessions, dependent: :destroy
  has_many :audit_batches, dependent: :destroy

  validates :provider, :uid, :email, :name, :siret, presence: true
  validates :uid, uniqueness: { scope: :provider, if: :uid_changed? }
  validates :email, uniqueness: { scope: :provider, if: :email_changed? }
  validates :email, email: true

  normalizes :email, with: ->(value) { value.strip.downcase }
  normalizes :siret, with: ->(value) { value.to_s.gsub(/\D/, "") }

  before_validation :find_or_create_team, on: :create

  def to_s
    name
  end

  class << self
    def from_omniauth(auth)
      data_source = auth.info
      extra_data = auth.provider == "developer" ? data_source : auth.extra.raw_info
      siret = extra_data.siret

      user = find_or_initialize_by(provider: auth.provider, uid: auth.uid)
      user.assign_attributes(
        siret:,
        email: data_source.email,
        name: data_source.name
      )
      user.team ||= Team.find_or_initialize_by(siret:) unless user.siret == user.team&.siret
      user.team.save if user.valid?
      return unless user.save

      user.team.update(organization_label: extra_data.organization_label)
      user
    end
  end

  private

  def find_or_create_team
    self.team ||= Team.find_or_create_by(siret:)
  end
end
