class Site < ApplicationRecord
  extend FriendlyId

  belongs_to :team, touch: true
  has_many :audits, -> { sort_by_newest }, dependent: :destroy
  has_many :site_tags, dependent: :destroy
  has_many :tags, -> { in_alphabetical_order }, through: :site_tags
  accepts_nested_attributes_for :tags, reject_if: :all_blank

  scope :with_current_audit, -> { joins(:audits).merge(Audit.current) }
  scope :preloaded, -> { with_current_audit.includes(:tags, :slugs, audits: { checks: :check_transitions }) }

  before_validation :set_normalized_url, if: :will_save_change_to_url?
  after_save :set_current_audit!, unless: -> { audits_count == audits_count_before_last_save }

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

  def update_slug!
    tap { self.slug = nil; friendly_id }.save!
  end

  def audit
    audits.find(&:current?) || audits.current.last || audits.first || audits.build(current: true)
  end

  def audit!
    audits.create!(url:, current: audits.current.none? || audits.none?)
  end

  def actual_current_audit
    audits.completed.sort_by_newest.first || audits.sort_by_newest.first
  end

  def set_current_audit!
    return if actual_current_audit && audit == actual_current_audit

    transaction do
      audit&.update!(current: false)
      actual_current_audit&.update!(current: true)
      update_slug!
    end
  end

  def tags_list
    tags.collect(&:name).join(", ")
  end
end
