class Audit < ApplicationRecord
  belongs_to :site, touch: true, counter_cache: true
  has_many :checks, -> { prioritized }, dependent: :destroy

  after_create_commit :create_checks
  after_create_commit :schedule

  validates :url, presence: true, url: true
  normalizes :url, with: ->(url) { Link.normalize(url).to_s }

  scope :sort_by_newest, -> { order(created_at: :desc) }
  scope :sort_by_url, -> { order(Arel.sql("REGEXP_REPLACE(audits.url, '^https?://(www\.)?', '') ASC")) }
  scope :checked, -> { where.not(checked_at: nil) }
  scope :current, -> { where(current: true) }
  scope :with_check_transitions, -> { includes(checks: :check_transitions) }

  Check.types.each do |name, klass|
    define_method(name) do
      instance_variable_get("@#{name}") ||
        instance_variable_set("@#{name}", checks.to_a.find { |check| klass === check } || checks.build(type: klass))
    end
  end

  def page(kind)
    page_url = case kind.to_s.to_sym
    when :home then url
    when :accessibility then find_accessibility_page&.url
    else
      raise ArgumentError, "Don't know how to find a page of kind '#{kind}'"
    end
    Page.new(url: page_url, root: url) if page_url
  end

  def schedule = ProcessAuditJob.set(group: "audit_#{id}").perform_later(self)

  def all_checks
    Check.names.map { |name| public_send(name) }
  end

  def check_completed?(identifier)
    send(identifier).completed?
  end

  def create_checks
    all_checks.select(&:new_record?).each(&:save)
  end

  def all_check_states
    all_checks.collect(&:current_state)
  end

  def pending?
    checked_at.nil?
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

  def complete?
    checks.remaining.none?
  end

  def after_check_completed
    if complete?
      update!(checked_at: Time.zone.now)
      site.set_current_audit!
    else
      ProcessAuditJob.perform_later(self)
    end
  end

  def abort_dependent_checks!(check)
    checks
      .remaining
      .filter { |other_check| other_check.depends_on?(check.to_requirement) }
      .each { |other_check| other_check.transition_to!(:aborted) }
  end
end
