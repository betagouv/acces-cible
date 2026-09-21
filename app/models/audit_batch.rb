class AuditBatch < ApplicationRecord
  MAX_SITES = 10
  STEPS = %w[method urls summary checks].freeze

  belongs_to :user
  has_many :audits

  enum :kind, { manual: "manual", csv_import: "csv_import" }, validate: true

  attribute :urls, default: -> { [] }
  attribute :site_tag_names, default: -> { {} }
  attribute :file
  normalizes :urls, with: ->(list) { list.compact_blank.uniq { Link.url_without_scheme_and_www(it) } }

  validates :kind, presence: true
  validates :urls, length: { minimum: 1, maximum: MAX_SITES }, on: :urls_step, if: :manual?
  validate :import_csv, on: :urls_step, if: -> { csv_import? && urls.empty? }
  validates :urls, length: { maximum: CsvSiteParser::MAX_ROWS }, on: :urls_step, if: :csv_import?
  validate :submitted_sites_urls, on: :urls_step, if: :manual?

  delegate :team, to: :user

  def submitted_sites
    @submitted_sites ||= urls.map do |url|
      normalized_url = Link.url_without_scheme_and_www(url)
      existing_sites[normalized_url] || team.sites.new(url:, normalized_url:)
    end
  end

  def site_tag_names=(names_by_site)
    self[:site_tag_names] = names_by_site.to_h.transform_values { Tag.parse_names(it) }
  end

  def launch
    return false unless save(context: [:method_step, :urls_step])

    sites_data.in_groups_of(100, false) { ProcessAuditBatchCreationJob.perform_later(it, team.id, user.id, id) }
  end

  def complete?
    audits.exists? && audits.where(completed_at: nil).none?
  end

  def progress
    { total: audits.count, completed: audits.completed.count }
  end

  private

  def existing_sites
    @existing_sites ||= team.sites.where(normalized_url: urls.map { Link.url_without_scheme_and_www(it) }).index_by(&:normalized_url)
  end

  def submitted_sites_urls
    errors.add(:submitted_sites, :invalid) if submitted_sites.select(&:new_record?).reject(&:valid?).any?
  end

  def import_csv
    sites_data = CsvSiteParser.new(file:, team:, errors:).parse_data!
    self.urls = sites_data.pluck("url")
    self.site_tag_names = sites_data.to_h { [Link.url_without_scheme_and_www(it["url"]), it["tag_names"]] }
  end

  def sites_data
    submitted_sites.map do |site|
      {
        "url" => site.url,
        "tag_names" => Array(site_tag_names[site.normalized_url])
      }
    end
  end
end
