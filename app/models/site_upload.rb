class SiteUpload
  include ActiveModel::Model
  include ActiveRecord::Store

  ALLOWED_CONTENT_TYPES = ["text/csv"].freeze
  MAX_FILE_SIZE = 5.megabytes
  REQUIRED_HEADERS = ["url"].freeze
  BOM = /^\xEF\xBB\xBF/

  attr_accessor :file

  validates :file, presence: true
  validate :valid_file_size, :valid_file_format, :valid_headers, if: :file

  delegate :create!, :transaction, :human, :model_name, to: :Site

  store_accessor :data, :new_sites, :existing_sites

  def save
    return false unless valid?

    parse_sites

    transaction do
      create!(new_sites) if new_sites.any?
      existing_sites.each(&:audit!)
    end
    true
  end

  def persisted? = false

  def parse_sites
    require "csv"

    new_sites = []
    existing_sites = []

    CSV.foreach(file.path, headers: true, encoding: "bom|utf-8") do |row|
      url = row["url"] || row["URL"]
      if existing_site = Site.find_by_url(url:)
        existing_sites << existing_site
      else
        new_sites << { url:, name: row["name"] }
      end
    end
    { new_sites:, existing_sites: }
  end

  private

  def valid_file_size
    errors.add(:file, :invalid_size) if file.size.zero? || file.size > MAX_FILE_SIZE
  end

  def valid_file_format
    errors.add(:file, :invalid_format) unless ALLOWED_CONTENT_TYPES.include?(file.content_type)
  end

  def valid_headers
    first_line = File.open(file.path, &:gets)&.strip&.sub(BOM, "") || ""
    headers = CSV.parse_line(first_line) || []
    missing_headers = REQUIRED_HEADERS - headers.collect(&:downcase)
    errors.add(:file, :invalid_headers) unless missing_headers.empty?
  rescue CSV::MalformedCSVError, StandardError
    errors.add(:file, :invalid_headers)
  end
end
