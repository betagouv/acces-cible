class Site < ApplicationRecord
  extend FriendlyId

  has_many :audits, dependent: :destroy
  has_one_of_many :audit, -> { past.order("audits.created_at DESC") }

  friendly_id :url_without_scheme, use: [:slugged, :history]

  delegate :url, :url_without_scheme, to: :audit

  scope :sort_by_audit_url, -> { joins(:audits).merge(Audit.sort_by_url) }

  class << self
    def find_or_create_by_url(attributes)
      url = attributes.to_h.delete(:url)
      attributes.to_h.delete(:name) if attributes[:name].blank?
      # Ignore http/https duplicates when searching
      normalized_url = [url, url.sub(/^https?/, url.start_with?("https") ? "http" : "https")]
      joins(:audits).find_by(audits: { url: normalized_url })&.tap { it.update(attributes) } \
        || create_with_audit(url:, **attributes)
    end

    def create_with_audit(url: nil, **attributes)
      new_with_audit(url:, **attributes).tap(&:save)
    end

    def new_with_audit(url: nil, **attributes)
      new(attributes).tap { |site| site.audits.build(url:) }
    end
  end

  def new(attributes = nil)
    return super if attributes.nil?

    attributes = attributes.to_h.symbolize_keys

    if url = attributes.delete(:url)
      self.class.find_or_create_by(url:, **attributes)
    else
      super
    end
  end

  def url=(new_url)
    audit = audits.build(url: new_url)
  end

  def to_title = url_without_scheme
  def audit = super || audits.last || audits.build
  def should_generate_new_friendly_id? = new_record? || (audit && slug != url_without_scheme.parameterize)
end
