class Site < ApplicationRecord
  extend FriendlyId

  has_many :audits, dependent: :destroy

  scope :preloaded, -> { joins(:audits).includes(audits: :checks).merge(Audit.current) }

  friendly_id :url_without_scheme, use: [:slugged, :history]

  delegate :url, to: :audit, allow_nil: true

  class << self
    def find_by_url(attributes)
      url = attributes.to_h.fetch(:url).strip
      return if url.empty?

      attributes.delete(:name) if attributes[:name].blank?
      # Ignore http/https duplicates when searching
      normalized_url = [url, url.sub(/^https?/, url.start_with?("https") ? "http" : "https")]
      joins(:audits).find_by(audits: { url: normalized_url })
    end
  end

  def url=(new_url)
    if audit.persisted? && url != new_url
      audits.build(url: new_url)
    else
      audit.url = new_url
    end
  end

  def parsed_url = Link.parse(url)
  def url_without_scheme = [parsed_url.hostname, parsed_url.path == "/" ? nil : parsed_url.path].compact.join(nil)

  def name = super.presence || url_without_scheme
  alias to_title name
  def should_generate_new_friendly_id? = new_record? || (audit && slug != url_without_scheme.parameterize)

  def audit
    audits.find(&:current?) || audits.current.last || audits.sort_by(&:checked_at).last || audits.build
  end

  def audit!
    audits.create!(url:).tap(&:schedule)
  end

  def set_current_audit!
    current = audits.current.last
    latest = audits.checked.sort_by_newest.last
    return if current == latest

    transaction do
      current.update!(current: false)
      latest.update!(current: true)
      update!(url: latest.url)
    end
  end
end
