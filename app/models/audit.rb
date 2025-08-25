class Audit < ApplicationRecord
  belongs_to :site, touch: true, counter_cache: true
  has_many :checks, -> { prioritized }, dependent: :destroy

  after_create_commit :create_checks
  after_create_commit :schedule

  validates :url, presence: true, url: true
  normalizes :url, with: ->(url) { Link.normalize(url).to_s }

  scope :sort_by_newest, -> { order(arel_table[:checked_at].desc.nulls_last, arel_table[:created_at].desc) }
  scope :sort_by_url, -> { order(Arel.sql("REGEXP_REPLACE(audits.url, '^https?://(www\.)?', '') ASC")) }
  scope :checked, -> { where.not(checked_at: nil) }
  scope :current, -> { where(current: true) }

  scope :with_check_transitions, -> { includes(checks: :check_transitions) }

  Check.types.each do |name, klass|
    define_method(name) do
      checks.to_a.find { |check| check.type == klass.name }
    end
  end

  def schedule = ProcessAuditJob.set(group: "audit_#{id}").perform_later(self)

  def all_checks
    Check.types.map { |name, klass| send(name) || checks.build(type: klass) }
  end

  def check_completed?(identifier)
    send(identifier).completed?
  end

  def create_checks
    all_checks.select(&:new_record?).each(&:save)
  end

  def all_check_states
    all_checks.map(&:current_state)
  end

  def status_from_checks
    states = all_check_states

    if states.uniq.one?
      states.first
    elsif states.include?("pending")
      :pending
    else
      :mixed
    end
  end

  def update_from_checks
    transaction do
      site.set_current_audit! unless pending?
    end
  end

  def complete?
    checks.remaining.none?
  end

  def after_check_completed
    if complete?
      update!(checked_at: Time.zone.now)
    else
      ProcessAuditJob.perform_later(self)
    end
  end

  def abort_dependent_checks!(check)
    checks
      .remaining
      .filter { |other_check| other_check.depends_on?(check.to_requirement) }
      .each { |other_check| other_check.transition_to!(:failed) }
  end
end
