class Site < ApplicationRecord
  extend FriendlyId

  belongs_to :team, touch: true

  has_many :audits, -> { sort_by_newest }, dependent: :destroy

  has_one :last_audit, -> { order(created_at: :desc) }, class_name: "Audit"

  has_many :site_tags, dependent: :destroy
  has_many :tags, -> { in_alphabetical_order }, through: :site_tags

  accepts_nested_attributes_for :tags, reject_if: :all_blank

  scope :preloaded, -> { preload(:tags, :slugs, last_audit: { checks: :check_transitions }) }

  before_validation :set_normalized_url, if: :will_save_change_to_url?

  friendly_id :normalized_url, use: [:slugged, :history, :scoped], scope: :team_id

  validates :url, presence: true, url: true

  broadcasts_refreshes

  def set_normalized_url
    self.normalized_url = Link.url_without_scheme_and_www(url)
  end

  def name_with_fallback
    name.presence || normalized_url
  end

  alias to_title name_with_fallback
  alias to_s name_with_fallback

  def tags_attributes=(attributes)
    return if (name = attributes[:name]).blank?

    tags << team.tags.find_or_create_by(name:)
  end

  def should_generate_new_friendly_id?
    new_record? || (slug != normalized_url.parameterize) || super
  end

  def audit!
    audits.create!(url:)
  end

  def tags_list
    tags.collect(&:name).join(", ")
  end
end
