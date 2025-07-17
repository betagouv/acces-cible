class Audit < ApplicationRecord
  belongs_to :site, touch: true, counter_cache: true
  has_many :checks, -> { prioritized }, dependent: :destroy

  after_create :create_checks

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
  scope :to_schedule, -> { pending.where(scheduled: false).joins(:checks).merge(Check.to_schedule) }
  scope :current, -> { where(current: true) }

  Check.types.each do |name, klass|
    define_method(name) do
      checks.to_a.find { |check| check.type == klass.name }
    end
  end

  def schedule(wait: 0)
    return if scheduled?

    transaction do
      RunAuditJob.set(wait:).perform_later(self)
      update!(scheduled: true)
    end
  end

  def all_checks
    Check.types.map { |name, klass| send(name) || checks.build(type: klass) }
  end

  def check_status(check)
    (send(check)&.status || :pending).to_s.inquiry
  end

  def derive_status_from_checks
    self.status = if all_checks.any?(&:new_record?)
       :pending
    elsif (check_statuses = checks.collect(&:status).uniq).one?
       check_statuses.first
    else
       :mixed
    end
    update(status:)
  end

  def set_checked_at
    latest_checked_at = checks.collect(&:checked_at).compact.sort.last
    update(checked_at: latest_checked_at)
  end

  def create_checks
    all_checks.select(&:new_record?).each(&:save)
  end
end
