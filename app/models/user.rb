class User < ApplicationRecord
  validates :provider, :uid, :email, :given_name, :usual_name, :siret, presence: true
  validates :uid, uniqueness: { scope: :provider, if: :uid_changed? }
  validates :email, uniqueness: true, if: :email_changed?
  validates :email, email: true

  normalizes :email, with: ->(value) { value.strip.downcase }
  normalizes :siret, with: ->(value) { value.to_s.gsub(/[^a-zA-Z0-9]/, "") }
end
