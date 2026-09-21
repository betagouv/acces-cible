class Tag < ApplicationRecord
  extend FriendlyId

  belongs_to :team
  has_many :site_tags, dependent: :destroy
  has_many :sites, through: :site_tags

  friendly_id :name, use: [:slugged, :history, :scoped], scope: :team_id

  validates :name, presence: true
  validates :name, uniqueness: { scope: :team_id }, if: :name_changed?

  scope :in_alphabetical_order, -> { order(:name) }

  def self.parse_names(names)
    Array(names).flat_map { it.to_s.split(",") }.map(&:strip).compact_blank.uniq
  end

  def to_s
    name
  end

  def should_generate_new_friendly_id?
    name_changed? || super
  end
end
