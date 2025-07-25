class Check < ApplicationRecord
  TYPES = [
    :reachable,
    :language_indication,
    :accessibility_mention,
    :find_accessibility_page,
    :analyze_accessibility_page,
    :accessibility_page_heading,
    :run_axe_on_homepage,
  ].freeze

  MAX_RETRIES = 3
  PRIORITY = 100 # Override in subclasses if necessary, lower numbers run first
  REQUIREMENTS = [:reachable]

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
  scope :retryable, -> { where("retry_count < ? AND (error_type IS NULL OR error_type LIKE 'Ferrum%')", MAX_RETRIES) }
  scope :retry_due, -> { where("retry_at IS NULL OR retry_at <= now()") }
  scope :to_retry, -> { where(status: [:failed, :blocked]).retryable.retry_due }
  scope :to_run, -> { due.or(to_retry) }

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
  def retryable? = retry_count < MAX_RETRIES && (error_type.nil? || error_type.start_with?("Ferrum"))
  def tooltip? = true

  def calculate_retry_at
    return nil unless retryable?

    (5 * (5 ** retry_count)).minutes.from_now # Exponential backoff: 5min, 25min, 125min (2h5m)
  end

  def to_badge
    [status_to_badge_level, status_to_badge_text, status_link].compact
  end

  def run
    if waiting?
      return false
    elsif blocked?
      block!
      return false
    elsif retry_at && retry_at > Time.current
      return false  # Not ready to retry yet
    end

    begin
      self.data = analyze!
      pass!
    rescue StandardError => exception
      fail!(exception)
    end
    passed?
  end

  def error
    error_type.constantize.new(error_message).tap { |err| err.set_backtrace(Array(error_backtrace)) } if error_type && error_message
  end

  private

  def analyze! = raise NotImplementedError.new("#{model_name} needs to implement the `#{__method__}` private method")

  def pass!
    self.error = nil
    update!(
      status: :passed,
      checked_at: Time.zone.now,
      retry_at: nil
    )
  end

  def fail!(exception)
    self.error = exception
    update!(
      status: :failed,
      checked_at: Time.zone.now,
      retry_count: retry_count + 1,
      retry_at: retryable? ? calculate_retry_at : nil
    )
    report(exception)
  end

  def block!
    update!(
      status: :blocked,
      checked_at: Time.zone.now,
      retry_at: calculate_retry_at
    )
  end

  def error=(exception = nil)
    if exception
      self.error_message = exception.message
      self.error_type = exception.class.name
      self.error_backtrace = Rails.backtrace_cleaner.clean(exception.backtrace)
    else
      self.error_message = self.error_type = self.error_backtrace = nil
    end
  end

  def status_to_badge_level
    case
    when failed? then :error
    when pending? || blocked? then :info
    when passed? && respond_to?(:custom_badge_status, true) then custom_badge_status
    else :success
    end
  end

  def status_to_badge_text = passed? && respond_to?(:custom_badge_text, true) ? custom_badge_text : human_status
  def status_link = passed? && respond_to?(:custom_badge_link, true) ? custom_badge_link : nil

  def set_priority = self.priority = self.class.priority

  def report(exception)
    return unless Sentry.initialized?

    Sentry.with_scope do |scope|
      scope.set_context("check", { id:, type:, retry_count: })
      scope.set_context("audit", { id: audit_id, url: audit.url })
      Sentry.capture_exception(exception)
    end
  end
end
