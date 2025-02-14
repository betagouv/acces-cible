class Check < ApplicationRecord
  MAX_ATTEMPTS = 3
  MAX_RUNTIME = 1.hour.freeze
  TYPES = [
  ].freeze

  belongs_to :audit

  enum :status, ["pending", "running", "passed", "retryable", "failed"].index_by(&:itself), validate: true, default: :pending

  delegate :parsed_url, to: :audit
  delegate :human_type, to: :class

  scope :due, -> { pending.where("run_at <= now()") }
  scope :past, -> { where(status: [:passed, :failed]) }
  scope :scheduled, -> { where("run_at > now()") }
  scope :to_run, -> { due.or(retryable) }
  scope :clean, -> { passed.where(attempts: 0) }
  scope :late, -> { pending.where("run_at <= ?", 1.hour.ago) }
  scope :retried, -> { passed.where(attempts: 1..) }
  scope :stalled, -> { running.where("run_at < ?", MAX_RUNTIME.ago) }
  scope :crashed, -> { failed.where(attempts: MAX_ATTEMPTS..) }

  class << self
    def human_type = human("checks.#{model_name.element}.type")

    def types
      @types ||= TYPES.index_with { |type| "Checks::#{type.to_s.classify}".constantize }
    end
    def classes = types.values
  end

  def run_at = super || audit&.run_at || Time.current
  def human_status = Check.human("status.#{status}")
  def human_checked_at = checked_at ? l(checked_at, format: :long) : nil
  def to_partial_path = self.class.model_name.collection.singularize
  def due? = pending? && run_at <= Time.current
  def runnable? = due? || retryable?
  def root_page = Page.new(audit.url)

  def run
    return false unless runnable?

    self.data = analyze!
    self.status = :passed
  rescue StandardError => e
    self.attempts += 1
    self.status = attempts < MAX_ATTEMPTS ? :retryable : :failed
    self.data = { error: e.message, error_type: e.class.name }
  ensure
    self.checked_at = Time.zone.now
    save
    passed?
  end

  private

  def analyze! = raise NotImplementedError.new("#{model_name} needs to implement the `#{__method__}` private method")
end
