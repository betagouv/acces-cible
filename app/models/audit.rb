class Audit < ApplicationRecord
  belongs_to :site, counter_cache: true
  belongs_to :user
  has_many :checks, -> { prioritized }, dependent: :destroy
  has_many :page_snapshots, dependent: :destroy

  after_create_commit :fetch_resources!, :create_checks

  scope :sort_by_newest, -> { order(created_at: :desc) }
  scope :completed, -> { where.not(completed_at: nil) }
  scope :with_check_transitions, -> { includes(checks: :check_transitions) }

  Check.types.each do |name, klass|
    define_method(name) do
      instance_variable_get("@#{name}") ||
        instance_variable_set("@#{name}", checks.to_a.find { |check| klass === check } || checks.build(type: klass))
    end
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
      current_timestamp = Time.zone.now
      update!(completed_at: current_timestamp)
      site.update!(last_audited_at: current_timestamp)
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

  def page_for(kind)
    snapshot = page_snapshots.find_by(kind:)
    return unless snapshot

    Page.new(url: snapshot.current_url, root: home_page_url, html: snapshot.html)
  end
end
