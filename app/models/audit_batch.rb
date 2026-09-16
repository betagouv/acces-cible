class AuditBatch < ApplicationRecord
  MAX_SITES = 10
  STEPS = %w[method urls summary checks].freeze
  AVAILABLE_KINDS = %w[manual].freeze

  belongs_to :user
  has_many :audits

  enum :kind, { manual: "manual", csv_import: "csv_import" }, validate: true

  attribute :urls, default: -> { [] }
  attribute :site_tags, default: -> { {} }
  normalizes :urls, with: ->(list) { list.compact_blank.uniq { Link.url_without_scheme_and_www(it) } }

  validates :kind, presence: true
  validates :kind, inclusion: { in: AVAILABLE_KINDS }, on: :method_step
  validates :urls, length: { minimum: 1, maximum: MAX_SITES }, on: :urls_step
  validates :submitted_sites, associated: true, on: :urls_step

  delegate :team, to: :user

  def submitted_sites
    @submitted_sites ||= urls.map { find_or_build_site(it) }
  end

  def launch
    return false unless save(context: [:method_step, :urls_step])

    ProcessAuditBatchCreationJob.perform_later(sites_data, team.id, [], user.id, id)
  end

  def complete?
    audits.exists? && audits.where(completed_at: nil).none?
  end

  def progress
    { total: audits.count, completed: audits.completed.count }
  end

  private

  def find_or_build_site(url)
    normalized_url = Link.url_without_scheme_and_www(url)
    team.sites.find_by(normalized_url:) || team.sites.new(url:)
  end

  def sites_data
    submitted_sites.map do |site|
      {
        "url" => site.url,
        "tag_ids" => site_tags.dig(site.normalized_url, :tag_ids),
        "tag_names" => [site_tags.dig(site.normalized_url, :tags_attributes, :name)].compact_blank
      }
    end
  end
end
