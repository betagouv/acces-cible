class AuditBatch < ApplicationRecord
  MAX_MANUAL_SITES = 10
  MAX_CSV_SITES = 2000
  STEPS = %w[method urls summary checks].freeze
  METHOD_STEP, URLS_STEP, SUMMARY_STEP, CHECKS_STEP = STEPS

  belongs_to :user
  has_many :audits

  enum :kind, { manual: "manual", csv_import: "csv_import" }, validate: true

  attribute :urls, default: -> { [] }
  attribute :site_tag_names, default: -> { {} }
  attribute :file
  attribute :requested_step
  normalizes :urls, with: ->(list) { list.compact_blank.uniq { Link.url_without_scheme_and_www(it) } }
  normalizes :site_tag_names, with: ->(names_by_site) { names_by_site.to_h.transform_values(&:compact_blank) }

  validates :kind, presence: true
  validates :urls, length: { minimum: 1, maximum: MAX_MANUAL_SITES }, on: :urls_step, if: :manual?
  validate :submitted_sites_urls, on: :urls_step, if: :manual?
  validate :import_csv, on: :urls_step, if: -> { csv_import? && urls.empty? }
  validates :urls, length: { maximum: MAX_CSV_SITES }, on: :urls_step, if: :csv_import?

  delegate :team, to: :user

  def current_step
    @current_step ||= requested_step.in?([SUMMARY_STEP, CHECKS_STEP]) && invalid?(:urls_step) ? URLS_STEP : requested_step
  end

  def previous_step
    STEPS[STEPS.index(current_step) - 1] unless current_step == STEPS.first
  end

  def next_step
    STEPS[STEPS.index(current_step) + 1]
  end

  def tag_names_for(site)
    site_tag_names[site.normalized_url] || []
  end

  def submitted_sites
    @submitted_sites ||= urls.map { team.sites.new(url: it).tap(&:set_normalized_url) }
  end

  def launch!
    return false unless save(context: :urls_step)

    ProcessSiteUploadJob.perform_later(sites_data, team.id, user.id, id)
  end

  def complete?
    audits.exists? && audits.where(completed_at: nil).none?
  end

  def progress
    { total: audits.count, completed: audits.completed.count }
  end

  private

  def submitted_sites_urls
    errors.add(:submitted_sites, :invalid) unless submitted_sites.all?(&:valid?)
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
        "tag_names" => tag_names_for(site)
      }
    end
  end
end
