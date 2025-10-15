class Site < ApplicationRecord
  extend FriendlyId

  belongs_to :team, touch: true
  has_many :audits, -> { sort_by_newest.current_first }, dependent: :destroy
  has_many :site_tags, dependent: :destroy
  has_many :tags, -> { in_alphabetical_order }, through: :site_tags
  accepts_nested_attributes_for :tags, reject_if: :all_blank

  scope :with_current_audit, -> { joins(:audits).merge(Audit.current.with_check_transitions) }
  scope :preloaded, -> { with_current_audit.includes(:tags, :audits) }

  after_save :set_current_audit!, unless: -> { audits_count == audits_count_before_last_save }

  friendly_id :url_without_scheme_and_www, use: [:slugged, :history, :scoped], scope: :team_id

  delegate :url, to: :audit, allow_nil: true

  broadcasts_refreshes

  class << self
    def find_by_url(attributes)
      url = attributes.to_h.fetch(:url).strip
      return if url.empty?

      # Ignore http/https duplicates when searching
      normalized_url = [url, url.sub(/^https?/, url.start_with?("https") ? "http" : "https")]
      joins(:audits).find_by(audits: { url: normalized_url })
    end
  end

  def url=(new_url)
    return if url == new_url

    if audit.pending?
      audit.url = new_url
      audit.save if audit.persisted?
    else
      audits.build(url: new_url)
    end
  end

  def url_without_scheme_and_www = Link.url_without_scheme_and_www(audit.url)

  def name_with_fallback = name.presence || url_without_scheme_and_www
  alias to_title name_with_fallback
  alias to_s name_with_fallback

  def tags_attributes=(attributes)
    return if (name = attributes[:name]).blank?

    tags << team.tags.find_or_create_by(name:)
  end

  def should_generate_new_friendly_id? = new_record? || (slug != url_without_scheme_and_www.parameterize) || super

  def update_slug! = tap { self.slug = nil; friendly_id }.save!

  def audit
    audits.find(&:current?) || audits.first || audits.build(current: true)
  end

  def audit!
    audits.create!(url:, current: audits.current.none? || audits.none?)
  end

  def actual_current_audit
    audits.checked.order(checked_at: :desc).first || audits.order(created_at: :desc).first
  end

  def set_current_audit!
    audits.reload
    current_audit = actual_current_audit
    return if current_audit && audit == current_audit

    transaction do
      audit&.update!(current: false)
      current_audit&.update!(current: true)
      update_slug!
    end
  end

  def tags_list
    tags.collect(&:name).join(", ")
  end
end
