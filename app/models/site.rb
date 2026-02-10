class Site < ApplicationRecord
  extend FriendlyId

  belongs_to :team, touch: true
  has_many :audits, -> { sort_by_newest }, dependent: :destroy
  has_many :site_tags, dependent: :destroy
  has_many :tags, -> { in_alphabetical_order }, through: :site_tags
  accepts_nested_attributes_for :tags, reject_if: :all_blank

  scope :preloaded, -> { includes(:tags, audits: { checks: :check_transitions }) }

  friendly_id :url_without_scheme_and_www, use: [:slugged, :history, :scoped], scope: :team_id

  delegate :url, to: :audit, allow_nil: true

  validates :url, presence: true, url: true

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

  def url_without_scheme_and_www
    Link.url_without_scheme_and_www(audit.url)
  end

  def name_with_fallback
    name.presence || url_without_scheme_and_www
  end

  alias to_title name_with_fallback
  alias to_s name_with_fallback

  def tags_attributes=(attributes)
    return if (name = attributes[:name]).blank?

    tags << team.tags.find_or_create_by(name:)
  end

  def should_generate_new_friendly_id?
    new_record? || (slug != url_without_scheme_and_www.parameterize) || super
  end

  def update_slug!
    tap { self.slug = nil; friendly_id }.save!
  end

  def audit
    audits.sort_by_newest.first || audits.build
  end

  def audit!
    audits.create!(url:)
  end

  def tags_list
    tags.collect(&:name).join(", ")
  end
end
