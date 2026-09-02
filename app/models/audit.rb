class Audit < ApplicationRecord
  belongs_to :site, counter_cache: true
  belongs_to :user
  belongs_to :audit_batch, optional: true
  has_many :checks, -> { prioritized }, dependent: :destroy
  has_many :page_snapshots, dependent: :destroy
  has_one :team, through: :user

  after_create_commit :start!, if: :launched?

  scope :sort_by_newest, -> { order(created_at: :desc) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :draft, -> { where(audit_batch_id: AuditBatch.draft) }
  scope :launched, -> { where(audit_batch_id: nil).or(where(audit_batch_id: AuditBatch.launched)) }
  scope :with_check_transitions, -> { includes(checks: :check_transitions) }
  scope :without_html, -> { select(column_names - %w[home_page_html accessibility_page_html]) }

  Check.types.each do |name, klass|
    define_method(name) do
      instance_variable_get("@#{name}") ||
        instance_variable_set("@#{name}", checks.to_a.find { |check| klass === check } || checks.build(type: klass))
    end
  end

  def launched?
    audit_batch.nil? || audit_batch.launched?
  end

  def draft?
    !launched?
  end

  def start!
    fetch_resources!
    create_checks
  end

  def fetch_resources!
    FetchResourcesJob.perform_later(self)
  end

  def check_completed?(identifier)
    send(identifier).completed?
  end

  def create_checks
    Check.types.each_value { |klass| checks.create!(type: klass.name) }
  end

  def all_check_states
    checks.collect(&:current_state)
  end

  def pending?
    completed_at.nil?
  end

  def status_from_checks
    states = all_check_states
    return :pending if states.empty?

    if states.uniq.one?
      states.first
    elsif states.include?("pending")
      :pending
    else
      :mixed
    end
  end

  def complete?
    checks.any? && checks.remaining.none?
  end

  def after_check_completed
    complete? ? finalize! : ProcessAuditJob.perform_later(self)
  end

  def finalize!
    current_timestamp = Time.zone.now
    update!(completed_at: current_timestamp,
            legal_obligation_score: compute_legal_obligation_score,
            declaration_quality_score: compute_declaration_quality_score)
    site.update!(last_audited_at: current_timestamp)
  end

  def compute_legal_obligation_score
    legal_obligation_checks = %i[analyze_accessibility_page accessibility_mention analyze_schema analyze_plan]

    legal_obligation_checks.count { |check| self.send(check).found }
  end

  def compute_declaration_quality_score
    declaration_quality_criteria.count { it } * 0.5
  end

  def declaration_quality_criteria
    declaration = analyze_accessibility_page&.data || {}

    [
      declaration["audit_date"].present?,
      declaration["standard"].present?,
      declaration["auditor"].present?,
      declaration["mentions_article"].present?,
      declaration["contact_email"].present? || declaration["contact_form"].present?,
      accessibility_page_heading&.conform,
      analyze_schema&.conform,
      analyze_plan&.conform
    ]
  end

  def declaration_quality_issues_count
    declaration_quality_criteria.count { !it }
  end

  def abort_dependent_checks!(check)
    checks
      .remaining
      .filter { |other_check| other_check.depends_on?(check.to_requirement) }
      .each { |other_check| other_check.transition_to!(:aborted) }
  end

  def page_for(kind)
    snapshot = page_snapshots.find_by(kind:)
    return unless snapshot

    Page.new(url: snapshot.current_url, root: home_page_url, html: snapshot.html)
  end
end
