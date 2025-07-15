class User < ApplicationRecord
  belongs_to :team, foreign_key: :siret, primary_key: :siret, inverse_of: :users, touch: true
  has_many :sites, through: :team
  has_many :sessions, dependent: :destroy

  scope :logged_in, -> { joins(:sessions) }
  scope :logged_out, -> { where.missing(:sessions) }
  scope :inactive, -> do
    with(inactive_users: [
      logged_out.where(updated_at: ..1.year.ago),
      logged_in.where(sessions: { created_at: ..18.months.ago })
    ]).from("inactive_users")
  end

  validates :provider, :uid, :email, :given_name, :usual_name, :siret, presence: true
  validates :uid, uniqueness: { scope: :provider, if: :uid_changed? }
  validates :email, uniqueness: { scope: :provider, if: :email_changed? }
  validates :email, email: true

  normalizes :email, with: ->(value) { value.strip.downcase }
  normalizes :siret, with: ->(value) { value.to_s.gsub(/\D/, "") }

  before_validation :find_or_create_team, on: :create

  class << self
    def from_omniauth(auth)
      data_source = auth.provider == "developer" ? auth.info : auth.extra.raw_info

      siret = data_source.siret

      user = find_or_initialize_by(provider: auth.provider, uid: auth.uid)
      user.assign_attributes(
        siret:,
        email: data_source.email,
        given_name: data_source.given_name,
        usual_name: data_source.usual_name
      )
      user.team ||= Team.find_or_initialize_by(siret:)
      user.team.save if user.valid?
      return unless user.save

      user.team.update(organizational_unit: data_source.organizational_unit)
      user
    end
  end

  def full_name
    "#{given_name} #{usual_name}"
  end

  alias to_title full_name

  private

  def find_or_create_team
    self.team ||= Team.find_or_create_by(siret:)
  end
end
