class Tag < ApplicationRecord
  extend FriendlyId

  belongs_to :team
  has_many :site_tags, dependent: :destroy
  has_many :sites, through: :site_tags

  friendly_id :name, use: [:slugged, :scoped], scope: :team_id

  validates :name, presence: true, uniqueness: { scope: :team_id }, if: :name_changed?

  scope :in_alphabetical_order, -> { order(:name) }
  scope :orphaned, -> { where.missing(:site_tags) }
  scope :not_recently_used, -> { where(updated_at: ..1.day.ago) }

  def to_s = name

  def should_generate_new_friendly_id? = name_changed? || super
end
