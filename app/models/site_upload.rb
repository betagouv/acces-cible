class SiteUpload
  include ActiveModel::Model

  ALLOWED_CONTENT_TYPES = ["text/csv"].freeze
  MAX_FILE_SIZE = 5.megabytes
  REQUIRED_HEADERS = ["url"].freeze
  BOM = /^\xEF\xBB\xBF/

  attr_accessor :file, :team, :new_sites, :existing_sites

  validates :file, :team, presence: true
  validate :valid_file_size, :valid_file_format, :valid_headers, if: :file

  delegate :create!, :transaction, :human, :model_name, to: :Site

  def initialize(attributes = {})
    super
    @new_sites = []
    @existing_sites = []
  end

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

  def count
    (new_sites&.length || 0) + (existing_sites&.length || 0)
  end

  def parse_sites
    require "csv"

    CSV.foreach(file.path, headers: true, encoding: "bom|utf-8") do |row|
      url = row["url"] || row["URL"]
      if existing_site = team.sites.find_by_url(url:)
        self.existing_sites << existing_site
      else
        self.new_sites << { url:, name: row["name"], team: }
      end
    end
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
