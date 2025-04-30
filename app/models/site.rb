class Site < ApplicationRecord
  extend FriendlyId

  has_many :audits, dependent: :destroy
  has_one_of_many :audit, -> { checked.sort_by_newest }, dependent: :destroy

  scope :preloaded, -> { includes(:audit) }

  friendly_id :url_without_scheme, use: [:slugged, :history]

  delegate :url, :url_without_scheme, to: :audit

  class << self
    def find_by_url(attributes)
      url = attributes.to_h.fetch(:url).strip
      return if url.empty?

      attributes.delete(:name) if attributes[:name].blank?
      # Ignore http/https duplicates when searching
      normalized_url = [url, url.sub(/^https?/, url.start_with?("https") ? "http" : "https")]
      joins(:audits).find_by(audits: { url: normalized_url })&.tap { it.update(attributes) }
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
    audits.create!(url:).tap(&:schedule)
  end
end
