class Check < ApplicationRecord
  TYPES = [
    :reachable,
    :language_indication,
    :accessibility_mention,
    :find_accessibility_page,
    :analyze_accessibility_page,
  ].freeze

  PRIORITY = 100 # Override in subclasses if necessary, lower numbers run first
  REQUIREMENTS = [:reachable]

  belongs_to :audit
  has_one :site, through: :audit

  enum :status, ["pending", "passed", "failed"].index_by(&:itself), validate: true, default: :pending
  store_accessor :data, :error, :error_type, :backtrace

  delegate :parsed_url, to: :audit
  delegate :human_type, to: :class

  after_initialize :set_priority

  scope :due, -> { pending.where("run_at <= now()") }
  scope :scheduled, -> { where(scheduled: true) }
  scope :unscheduled, -> { where(scheduled: false) }
  scope :to_schedule, -> { due.unscheduled }
  scope :to_run, -> { due.scheduled }
  scope :prioritized, -> { order(:priority) }

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
  def to_partial_path = self.class.model_name.collection.singularize
  def due? = persisted? && pending? && run_at <= Time.current
  def root_page = @root_page ||= Page.new(url: audit.url)
  def crawler = Crawler.new(audit.url)
  def reschedule = update(status: :pending, scheduled: false, checked_at: nil)
  def requirements = self.class::REQUIREMENTS # Returns subclass constant value, defaults to parent class
  def waiting? = requirements&.any? { audit.check_status(it).pending? } || false
  def blocked? = requirements&.any? { audit.check_status(it).failed? } || false
  def cleared? = requirements.nil? || requirements.all? { audit.check_status(it).passed? }

  def to_badge
    [status_to_badge_level, status_to_badge_text, status_link].compact
  end

  def reschedule!
    transaction do
      RunCheckJob.set(wait_for: 1.minute).perform_later(self)
      update!(status: :pending, checked_at: nil, scheduled: true)
    end
  end

  def run
    return reschedule! if waiting?

    begin
      self.checked_at = Time.zone.now
      self.data = analyze!
      self.status = :passed
      passed?
    rescue StandardError => e
      self.status = :failed
      self.data = { error: e.message, error_type: e.class.name, backtrace: Rails.backtrace_cleaner.clean(e.backtrace) }
    end
    save
    passed?
  end

  def original_error
    error_type.constantize.new(error).tap { it.set_backtrace(backtrace) } if error
  end

  private

  def analyze! = raise NotImplementedError.new("#{model_name} needs to implement the `#{__method__}` private method")

  def status_to_badge_level
    case
    when pending? then :info
    when failed? then :error
    when passed? && respond_to?(:custom_badge_status, true) then custom_badge_status
    else :success
    end
  end

  def status_to_badge_text = passed? && respond_to?(:custom_badge_text, true) ? custom_badge_text : human_status
  def status_link = passed? && respond_to?(:custom_badge_link, true) ? custom_badge_link : nil

  def set_priority = self.priority = self.class.priority
end
