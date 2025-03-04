class Site < ApplicationRecord
  extend FriendlyId

  has_many :audits, dependent: :destroy
  has_one_of_many :audit, -> { past.sort_by_newest }, dependent: :destroy

  friendly_id :url_without_scheme, use: [:slugged, :history]

  delegate :url, :url_without_scheme, to: :audit

  scope :sort_by_audit_url, -> do
    sortable_url = Arel.sql("REGEXP_REPLACE(audits.url, '^https?://(www\.)?', '')")
    subquery = joins(:audits)
      .select("DISTINCT ON (sites.id) sites.*, #{sortable_url} as sortable_url")
      .order("sites.id, sortable_url")
    from(subquery, :sites).order(:sortable_url)
  end
  scope :sort_by_audit_date, -> do
    joins("LEFT JOIN (
        SELECT site_id, MAX(checked_at) as latest_check
        FROM audits
        GROUP BY site_id
      ) latest_audits ON sites.id = latest_audits.site_id")
    .order("latest_audits.latest_check DESC NULLS LAST, sites.created_at DESC")
  end

  class << self
    def find_or_create_by_url(attributes)
      url = attributes.to_h.fetch(:url).strip
      attributes.delete(:name) if attributes[:name].blank?
      # Ignore http/https duplicates when searching
      normalized_url = [url, url.sub(/^https?/, url.start_with?("https") ? "http" : "https")]
      joins(:audits).find_by(audits: { url: normalized_url })&.tap { it.update(attributes) } || create(attributes)
    end
  end

  def url=(new_url)
    audit = audits.build(url: new_url)
  end

  def name = super.presence || url_without_scheme
  alias to_title name
  def audit = super || audits.last || audits.build
  def should_generate_new_friendly_id? = new_record? || (audit && slug != url_without_scheme.parameterize)

  def audit!
    audits.create(url:).tap(&:run!).tap(&:persisted?)
  end
end
