class SiteUpload
  include ActiveModel::Model

  ALLOWED_CONTENT_TYPES = [
    "text/csv",
    "text/comma-separated-values",
    "text/x-csv",
    "text/plain",
    "application/csv",
    "application/vnd.ms-excel",
    "application/excel",
    "application/x-excel",
    "application/x-msexcel",
    "application/octet-stream"
  ].freeze
  MAX_FILE_SIZE = 5.megabytes
  REQUIRED_HEADERS = ["url"].freeze

  attr_accessor :file, :team, :tag_ids, :tags

  validates :file, :team, presence: true
  validate :valid_file_size, :valid_file_format, :valid_headers, if: :file

  def initialize(attributes = {})
    super
    @tag_ids ||= []
  end

  def save
    return false unless valid?

    sites_data = csv_parser.parse_data!
    return false if errors.any?

    ProcessSiteUploadJob.perform_later(sites_data, team.id, tag_ids)
    true
  end

  def persisted?
    false
  end

  def tags_attributes=(attributes)
    return if (name = attributes[:name]).blank?

    tag_ids << team.tags.find_or_create_by(name:).id
  end

  def assign_attributes(attributes)
    # Assign team before other attributes because tags is scoped by team
    super(attributes.slice(:team).merge(attributes))
  end

  private

  def csv_parser
    @csv_parser ||= CsvSiteParser.new(file:, team:, errors:)
  end

  def valid_file_size
    errors.add(:file, :invalid_size) if file.size.zero? || file.size > MAX_FILE_SIZE
  end

  def valid_file_format
    errors.add(:file, :invalid_format) unless file.original_filename&.ends_with?(".csv")
    errors.add(:file, :invalid_format) unless ALLOWED_CONTENT_TYPES.include?(file.content_type)
  end

  def valid_headers
    missing_headers = REQUIRED_HEADERS - csv_parser.headers
    errors.add(:file, :invalid_headers) unless missing_headers.empty?
  rescue CSV::MalformedCSVError, StandardError
    errors.add(:file, :invalid_headers)
  end
end
