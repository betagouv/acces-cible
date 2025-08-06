class Audit < ApplicationRecord
  belongs_to :site, touch: true, counter_cache: true
  has_many :checks, -> { prioritized }, dependent: :destroy

  after_create_commit :create_checks
  after_create_commit :schedule

  validates :url, presence: true, url: true
  normalizes :url, with: ->(url) { Link.normalize(url).to_s }

  enum :status, [
    "pending",    # Initial state, no checks started
    "passed",     # All checks passed
    "mixed",      # Some checks failed
    "failed",     # All checks failed
  ].index_by(&:itself), validate: true, default: :pending

  scope :sort_by_newest, -> { order(arel_table[:checked_at].desc.nulls_last, arel_table[:created_at].desc) }
  scope :sort_by_url, -> { order(Arel.sql("REGEXP_REPLACE(audits.url, '^https?://(www\.)?', '') ASC")) }
  scope :checked, -> { where.not(status: :pending) }
  scope :current, -> { where(current: true) }

  Check.types.each do |name, klass|
    define_method(name) do
      checks.to_a.find { |check| check.type == klass.name }
    end
  end

  def schedule = ProcessAuditJob.set(group: "audit_#{id}").perform_later(self)

  def all_checks
    Check.types.map { |name, klass| send(name) || checks.build(type: klass) }
  end

  def check_for(identifier)
    send(identifier)
  end

  def check_complete?(identifier)
    check_for(identifier).complete?
  end

  def check_status(check)
    (send(check)&.status || :pending).to_s.inquiry
  end

  def create_checks
    all_checks.select(&:new_record?).each(&:save)
  end

  def next_check
    checks.pending.first ||
    checks.to_retry.first ||
    checks.blocked.reject(&:blocked?).first
  end

  def status_from_checks
    if all_checks.any?(&:new_record?)
       :pending
    elsif (check_statuses = checks.collect(&:status).uniq).one?
       check_statuses.first.to_sym
    else
       :mixed
    end
  end

  def latest_checked_at = checks.collect(&:checked_at).compact.sort.last

  def update_from_checks
    transaction do
      update(status: status_from_checks, checked_at: latest_checked_at)
      site.set_current_audit! unless pending?
    end
  end
end
