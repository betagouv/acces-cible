class SiteUpload
  include ActiveModel::Model
  ALLOWED_CONTENT_TYPES = ["text/csv"].freeze
  MAX_FILE_SIZE = 5.megabytes
  REQUIRED_HEADERS = ["url"].freeze

  attr_accessor :file

  validates :file, presence: true
  validate :valid_file_size, :valid_file_format, :valid_headers, if: :file

  delegate :create!, :transaction, :human, :model_name, to: :Site

  def save
    return false unless valid?

    transaction do
      create!(sites)
    end
  end

  def persisted? = false

  def sites
    require "csv"

    parsed_sites = []
    CSV.foreach(file.path, headers: true) do |row|
      url = row["url"] || row["URL"]
      next if Site.find_by_url(url:)

      parsed_sites << { url:, name: row["name"] }
    end
    parsed_sites
  end

  private

  def valid_file_size
    errors.add(:file, :invalid_size) if file.size > MAX_FILE_SIZE
  end

  def valid_file_format
    errors.add(:file, :invalid_format) unless ALLOWED_CONTENT_TYPES.include?(file.content_type)
  end

  def valid_headers
    first_line = File.open(file.path, &:gets).strip
    headers = CSV.parse_line(first_line)
    missing_headers = REQUIRED_HEADERS - headers.collect(&:downcase)
    errors.add(:file, :invalid_headers) unless missing_headers.empty?
  end
end
