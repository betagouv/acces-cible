class Audit < ApplicationRecord
  belongs_to :site, touch: true
  Check.types.each do |name, klass|
    has_one name, class_name: klass.name, dependent: :destroy
  end

  validates :url, presence: true, url: true
  normalizes :url, with: ->(url) { URI.parse(url).normalize.to_s }

  enum :status, [
    "pending",    # Initial state, no checks started
    "passed",     # All checks passed
    "mixed",      # Some checks failed
    "failed",     # All checks failed
  ].index_by(&:itself), validate: true, default: :pending

  scope :sort_by_newest, -> { order(created_at: :desc) }
  scope :sort_by_url, -> { order(Arel.sql("REGEXP_REPLACE(audits.url, '^https?://(www\.)?', '') ASC")) }
  scope :past, -> { where(status: [:passed, :failed]) }

  delegate :hostname, :path, to: :parsed_url

  after_create_commit :create_checks

  def parsed_url = @parsed_url ||= URI.parse(url).normalize
  def url_without_scheme = @url_without_scheme ||= [hostname, path == "/" ? nil : path].compact.join(nil)

  def all_checks
    Check.names.map { |name| send(name) || send(:"build_#{name}") }
  end

  def create_checks
    Check.names.map { |name| send(name) || send(:"create_#{name}") }
  end

  def derive_status_from_checks
    new_status = if all_checks.any?(&:new_record?)
       :pending
    elsif (check_statuses = all_checks.collect(&:status).uniq).one?
       check_statuses.first
    else
       :mixed
    end
    update(status: new_status)
  end
end
