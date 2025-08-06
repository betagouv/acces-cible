class Check < ApplicationRecord
  # FIXME: begin state machine glue
  has_many :check_transitions, autosave: false, dependent: :destroy

  include Statesman::Adapters::ActiveRecordQueries[
            transition_class: CheckTransition,
            initial_state: :pending
          ]

  def state_machine
    @state_machine || CheckStateMachine.new(
      self,
      transition_class: CheckTransition,
      association_name: :check_transitions,
      initial_transition: true
    )
  end

  delegate :current_state,
           :transition_to!,
           :in_state?,
           to: :state_machine
  # FIXME: end state machine glue

  TYPES = [
    :reachable,
    :language_indication,
    :accessibility_mention,
    :find_accessibility_page,
    :analyze_accessibility_page,
    :accessibility_page_heading,
    :run_axe_on_homepage,
  ].freeze

  # used to signal a check's `run` method has failed
  class RuntimeError < StandardError; end

  PRIORITY = 100 # Override in subclasses if necessary, lower numbers run first
  REQUIREMENTS = [:reachable]
  MAX_RETRIES = 3
  RETRYABLE_ERRORS = [
    "Errno::ECONNREFUSED",
    "NoMethodError", # raised when Ferrum is restarted while a check is running
    "Ferrum::PendingConnectionsError",
    "Ferrum::ProcessTimeoutError",
    "Ferrum::StatusError",
    "Ferrum::TimeoutError",
    "ThreadError",
  ].freeze

  belongs_to :audit
  has_one :site, through: :audit

  enum :status, ["pending", "passed", "failed", "blocked"].index_by(&:itself), validate: true, default: :pending

  delegate :parsed_url, to: :audit
  delegate :human_type, to: :class

  after_initialize :set_priority

  scope :due, -> { pending.where("run_at <= now()") }
  scope :past, -> { where.not(status: [:pending, :blocked]) }
  scope :prioritized, -> { order(:priority) }
  scope :errored, ->(type = nil) { type ? where(error_type: type) : where.not(error_type: nil) }
  scope :retryable, -> { where("retry_count < ? AND error_type IN (?)", MAX_RETRIES, RETRYABLE_ERRORS) }
  scope :retry_due, -> { where("retry_at IS NULL OR retry_at <= now()") }
  scope :to_retry, -> { where(status: [:failed, :blocked]).retryable.retry_due }
  scope :to_run, -> { due.or(to_retry) }

  broadcasts_refreshes_to ->(check) { "sites" }

  class << self
    def human_type = human("checks.#{model_name.element}.type")
    def table_header = human("checks.#{model_name.element}.table_header", default: human_type)

    def types
      @types ||= TYPES.index_with { |type| "Checks::#{type.to_s.classify}".constantize }.sort_by { |_name, klass| klass.priority }.to_h
    end
    def names = types.keys
    def classes = types.values
    def priority = self::PRIORITY
  end

  def run_at = super || Time.current
  def human_status = Check.human("status.#{status}")
  def human_checked_at = checked_at ? l(checked_at, format: :long) : nil
  def to_partial_path = model_name.i18n_key.to_s
  def due? = persisted? && pending? && run_at <= Time.current
  def root_page = @root_page ||= Page.new(url: audit.url)
  def crawler = Crawler.new(audit.url)
  def requirements = self.class::REQUIREMENTS # Returns subclass constant value, defaults to parent class
  def waiting? = requirements&.any? { audit.check_status(it).pending? } || false
  def blocked? = requirements&.any? { audit.check_status(it).failed? || audit.check_status(it).blocked? } || false
  def retryable? = failed? && retry_count < MAX_RETRIES && RETRYABLE_ERRORS.include?(error_type)
  def tooltip? = true

  def calculate_retry_at
    (5 * (5 ** retry_count)).minutes.from_now # Exponential backoff: 5min, 25min, 125min (2h5m)
  end

  def run
    self.data = analyze!
  rescue StandardError => exception
    raise Check::RuntimeError.new(exception)
  end

  def all_requirements_met?
    requirements.all? { |requirement| audit.check_complete?(requirement) }
  end

  def complete?
    in_state?(:complete)
  end

  def error
    error_type.constantize.new(error_message).tap { |err| err.set_backtrace(Array(error_backtrace)) } if error_type && error_message
  end

  private

  def analyze! = raise NotImplementedError.new("#{model_name} needs to implement the `#{__method__}` private method")

  def set_priority = self.priority = self.class.priority
end
