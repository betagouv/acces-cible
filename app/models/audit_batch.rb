class AuditBatch < ApplicationRecord
  MAX_SITES = 10
  STEPS = %w[method urls summary checks].freeze
  AVAILABLE_KINDS = %w[manual].freeze

  belongs_to :user
  has_many :audits, dependent: :destroy
  has_many :sites, -> { distinct }, through: :audits

  enum :kind, { manual: "manual", csv_import: "csv_import" }, validate: true
  enum :status, { draft: "draft", launched: "launched" }

  validates :kind, presence: true
  validates :kind, inclusion: { in: AVAILABLE_KINDS }, on: :method_step
  validates :urls, length: { minimum: 1, maximum: MAX_SITES }, on: :urls_step
  validates :submitted_sites, associated: true, on: :urls_step

  after_save :replace_audits, if: :urls_submitted?
  after_save :apply_site_tags, if: :site_tags_submitted?
  after_save_commit :start_audits, if: -> { saved_change_to_status?(to: :launched) }

  delegate :team, to: :user

  def self.site_tags_scope(site)
    "#{model_name.param_key}[site_tags][#{site.id}]"
  end

  def urls=(list)
    @submitted_sites = Array(list)
      .map { it.to_s.strip }
      .compact_blank
      .uniq { Link.url_without_scheme_and_www(it).presence || it }
      .map { find_or_build_site(it) }
  end

  def urls
    submitted_sites.map(&:url)
  end

  def site_tags=(attributes)
    @site_tags = attributes.to_h
  end

  def submitted_sites
    @submitted_sites ||= audits.order(:id).includes(:site).map(&:site).uniq
  end

  def abandon!
    transaction do
      candidates = sites.to_a
      destroy!
      candidates.each { destroy_if_orphan(it) }
    end
  end

  def complete?
    audits.exists? && audits.where(completed_at: nil).none?
  end

  def progress
    { total: audits.count, completed: audits.completed.count }
  end

  def steps
    STEPS
  end

  def next_step(step)
    steps[steps.index(step) + 1]
  end

  def previous_step(step)
    index = steps.index(step)
    steps[index - 1] unless index.zero?
  end

  def first_incomplete_step
    steps.find { !step_complete?(it) } || steps.last
  end

  def step_reachable?(step)
    steps.take(steps.index(step)).all? { step_complete?(it) }
  end

  def step_complete?(step)
    case step
    when "method" then persisted?
    when "urls" then audits.exists?
    else true
    end
  end

  private

  def start_audits
    audits.each(&:start!)
  end

  def urls_submitted?
    !@submitted_sites.nil?
  end

  def site_tags_submitted?
    !@site_tags.nil?
  end

  def apply_site_tags
    sites.each do |site|
      next unless (attributes = @site_tags[site.id.to_s])

      site.update!(
        tag_ids: team.tags.where(id: attributes[:tag_ids].to_a.compact_blank).ids,
        tags_attributes: attributes[:tags_attributes] || {}
      )
    end

    @site_tags = nil
  end

  def find_or_build_site(url)
    normalized_url = Link.url_without_scheme_and_www(url)
    team.sites.find_by(normalized_url:) || team.sites.new(url:)
  end

  def replace_audits
    submitted_sites.each(&:save!)
    current = audits.includes(:site).to_a

    current.each { |audit| detach(audit) unless submitted_sites.include?(audit.site) }
    (submitted_sites - current.map(&:site)).each { |site| audits.create!(site:, user:) }

    @submitted_sites = nil
    audits.reset
  end

  def detach(audit)
    site = audit.site
    audit.destroy!
    destroy_if_orphan(site)
  end

  def destroy_if_orphan(site)
    site.destroy! if site.audits.reload.empty?
  end
end
