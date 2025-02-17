class Check < ApplicationRecord
  TYPES = [
    :accessibility_mention,
    :language_indication,
  ].freeze

  belongs_to :audit

  enum :status, ["pending", "passed", "failed"].index_by(&:itself), validate: true, default: :pending

  delegate :parsed_url, to: :audit
  delegate :human_type, to: :class

  scope :due, -> { pending.where("run_at <= now()") }
  scope :scheduled, -> { where(scheduled: true) }
  scope :unscheduled, -> { where(scheduled: false) }
  scope :to_schedule, -> { due.unscheduled }
  scope :to_run, -> { due.scheduled }

  class << self
    def human_type = human("checks.#{model_name.element}.type")
    def table_header = human("checks.#{model_name.element}.table_header") || human_type

    def types
      @types ||= TYPES.index_with { |type| "Checks::#{type.to_s.classify}".constantize }
    end
    def names = types.keys
    def classes = types.values
  end

  def run_at = super || Time.current
  def human_status = Check.human("status.#{status}")
  def human_checked_at = checked_at ? l(checked_at, format: :long) : nil
  def to_partial_path = self.class.model_name.collection.singularize
  def due? = persisted? && pending? && run_at <= Time.current
  def root_page = Page.new(audit.url)

  def to_badge
    [status_to_badge_level, status_to_badge_text]
  end

  def run
    self.data = analyze!
    self.status = :passed
  rescue StandardError => e
    self.status = :failed
    self.data = { error: e.message, error_type: e.class.name }
  ensure
    self.checked_at = Time.zone.now
    save
    passed?
  end

  private

  def analyze! = raise NotImplementedError.new("#{model_name} needs to implement the `#{__method__}` private method")

  def status_to_badge_level
    case
    when pending? then :info
    when failed? then :error
    when passed? && respond_to?(:custom_badge_status) then custom_badge_status
    else :success
    end
  end

  def status_to_badge_text = passed? && respond_to?(:custom_badge_text) ? custom_badge_text : human_status
end
