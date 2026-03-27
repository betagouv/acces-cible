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
  SUPPORTED_SEPARATORS = [",", ";"].freeze
  FIRST_DATA_ROW_NUMBER = 2 # Row 1 contains CSV headers
  BOM = /^\xEF\xBB\xBF/

  attr_accessor :file, :team, :tag_ids, :tags, :new_sites, :existing_sites

  validates :file, :team, presence: true
  validate :valid_file_size, :valid_file_format, :valid_headers, if: :file

  delegate :create!, :transaction, to: :Site

  def initialize(attributes = {})
    super
    @tag_ids ||= []
    @new_sites = {}
    @existing_sites = {}
  end

  def save
    return false unless valid?

    parse_sites
    return false if errors.any?

    transaction do
      create!(new_sites.values) if new_sites.any?
      existing_sites.values.each { |site| site.save && site.audit! }
    end
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

  def count
    (new_sites&.length || 0) + (existing_sites&.length || 0)
  end

  def parse_sites
    require "csv"

    CSV.foreach(file.path, headers: true, encoding: "bom|utf-8", col_sep:).with_index(FIRST_DATA_ROW_NUMBER) do |row, line_number|
      row = row.to_h.transform_keys { |header| header.to_s.downcase } # Case-insensitive headers

      raw_url = row["url"].to_s.strip
      next if raw_url.empty?

      begin
        parsed_url = Link.parse(raw_url)
        raise Link::InvalidUriError.new(raw_url) if parsed_url.relative?

        url = Link.normalize(parsed_url).to_s
      rescue Link::InvalidUriError => error
        Rails.logger.warn(
          "site_upload_invalid_url " \
          "team_id=#{team&.id.inspect} " \
          "filename=#{file&.original_filename.inspect} " \
          "line_number=#{line_number.inspect} " \
          "raw_url=#{raw_url.inspect} " \
          "error_class=#{error.class.name.inspect} " \
          "error_message=#{error.message.inspect}"
        )
        errors.add(:file, :invalid_row_url, line_number:, url: raw_url)
        next
      end
      name = row["nom"] || row["name"]
      tag_names = row["tags"].present? ? row["tags"].split(",").map(&:strip).compact_blank.uniq : []

      row_tag_ids = tag_names.map { |n| team.tags.find_or_create_by(name: n).id }
      combined_tag_ids = (tag_ids + row_tag_ids).uniq
      existing_site = team.sites.find_by_url(url:)

      if existing_site
        existing_site.assign_attributes(tag_ids: combined_tag_ids.union(existing_site.tag_ids))
        existing_site.assign_attributes(name:) unless existing_site.name
        self.existing_sites[url] = existing_site
      else
        self.new_sites[url] = { url:, team:, name:, tag_ids: combined_tag_ids }
      end
    end
  end

  private

  def first_line
    @first_line ||= File.open(file.path, &:gets)&.strip&.sub(BOM, "") || ""
  end

  def col_sep
    SUPPORTED_SEPARATORS.max_by { |sep| first_line.count(sep) }
  rescue StandardError
    SUPPORTED_SEPARATORS.first
  end

  def valid_file_size
    errors.add(:file, :invalid_size) if file.size.zero? || file.size > MAX_FILE_SIZE
  end

  def valid_file_format
    errors.add(:file, :invalid_format) unless file.original_filename&.ends_with?(".csv")
    errors.add(:file, :invalid_format) unless ALLOWED_CONTENT_TYPES.include?(file.content_type)
  end

  def valid_headers
    headers = CSV.parse_line(first_line, col_sep:) || []
    missing_headers = REQUIRED_HEADERS - headers.compact.collect(&:downcase)
    errors.add(:file, :invalid_headers) unless missing_headers.empty?
  rescue CSV::MalformedCSVError, StandardError
    errors.add(:file, :invalid_headers)
  end
end
