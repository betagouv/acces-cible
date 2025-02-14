class Audit < ApplicationRecord
  MAX_ATTEMPTS = 3
  MAX_RUNTIME = 1.hour.freeze

  belongs_to :site, touch: true

  validates :url, presence: true, url: true
  normalizes :url, with: ->(url) { URI.parse(url).normalize.to_s }

  enum :status, ["pending", "running", "passed", "retryable", "failed"].index_by(&:itself), validate: true, default: :pending

  scope :sort_by_newest, -> { order(created_at: :desc) }
  scope :sort_by_url, -> { order(Arel.sql("REGEXP_REPLACE(url, '^https?://(www\.)?', '') ASC")) }
  scope :due, -> { pending.where("run_at <= now()") }
  scope :past, -> { where(status: [:passed, :failed]) }
  scope :scheduled, -> { where("run_at > now()") }
  scope :to_run, -> { due.or(where(status: :retryable)) }
  scope :clean, -> { passed.where(attempts: 0) }
  scope :late, -> { pending.where("run_at <= ?", MAX_RUNTIME.ago) }
  scope :retried, -> { passed.where(attempts: 1..) }
  scope :stalled, -> { running.where("run_at < ?", MAX_RUNTIME.ago) }
  scope :crashed, -> { failed.where(attempts: MAX_ATTEMPTS..) }

  delegate :hostname, :path, to: :parsed_url

  def run_at = super || Time.zone.now
  def due? = pending? && run_at <= Time.zone.now
  def runnable? = due? || retryable?
  def parsed_url = @parsed_url ||= URI.parse(url).normalize
  def url_without_scheme = @url_without_scheme ||= [hostname, path == "/" ? nil : path].compact.join(nil)
end
