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
  BOM = /^\xEF\xBB\xBF/

  attr_accessor :file, :team, :tag_ids, :tags, :new_sites, :existing_sites

  validates :file, :team, presence: true
  validate :valid_file_size, :valid_file_format, :valid_headers, if: :file

  delegate :create!, :transaction, :human, to: :Site

  def initialize(attributes = {})
    super
    @tag_ids ||= []
    @new_sites = {}
    @existing_sites = {}
  end

  def save
    return false unless valid?

    parse_sites

    transaction do
      create!(new_sites.values) if new_sites.any?
      existing_sites.values.each { |site| site.save && site.audit! }
    end
    true
  end

  def persisted? = false

  def tags_attributes=(attributes)
    return if (name = attributes[:name]).blank?

    tag_ids << team.tags.find_or_create_by(name:).id
  end

  def assign_attributes(attributes)
    # Assign team before other attributes because tags is scoped by team
    super(attributes.slice(:team).merge(attributes))
  end

  def count
    (new_sites&.length || 0) + (existing_sites&.length || 0)
  end

  def parse_sites
    require "csv"

    CSV.foreach(file.path, headers: true, encoding: "bom|utf-8") do |row|
      row = row.to_h.transform_keys(&:downcase) # Case-insensitive headers

      url = Link.normalize(row["url"])
      name = row["nom"] || row["name"]
      if existing_site = team.sites.find_by_url(url:)
        existing_site.assign_attributes(tag_ids: tag_ids.union(existing_site.tag_ids))
        existing_site.assign_attributes(name:) unless existing_site.name
        self.existing_sites[url] = existing_site
      else
        self.new_sites[url] = { url:, team:, name:, tag_ids: }
      end
    end
  end

  private

  def valid_file_size
    errors.add(:file, :invalid_size) if file.size.zero? || file.size > MAX_FILE_SIZE
  end

  def valid_file_format
    errors.add(:file, :invalid_format) unless file.original_filename&.ends_with?(".csv")
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
