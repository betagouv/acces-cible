class CsvSiteParser
  require "csv"

  BOM = /^\xEF\xBB\xBF/
  FIRST_DATA_ROW_NUMBER = 2 # Row 1 contains CSV headers
  SUPPORTED_SEPARATORS = [",", ";"].freeze
  REQUIRED_HEADERS = ["url"].freeze
  MAX_ROWS = 2000
  MAX_FILE_SIZE = 5.megabytes
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

  def initialize(file:, team:, errors:)
    @file = file
    @team = team
    @errors = errors
  end

  def parse_data!
    return [] unless valid_file?

    sites_by_url = {}

    CSV.foreach(file.path, headers: true, encoding: "bom|utf-8", col_sep:).with_index(FIRST_DATA_ROW_NUMBER) do |row, line_number|
      row = row.to_h.transform_keys { |header| header.to_s.downcase }

      raw_url = row["url"].to_s.strip
      next if raw_url.empty?

      url = normalize_url(raw_url, line_number)
      next unless url

      merge_site_data!(sites_by_url, url, row)
      break if sites_by_url.size > MAX_ROWS
    end

    if sites_by_url.size > MAX_ROWS
      errors.add(:file, :too_many_rows, max: MAX_ROWS)
      return []
    end

    errors.add(:file, :blank) if sites_by_url.empty? && errors[:file].none?
    sites_by_url.values
  rescue CSV::MalformedCSVError => error
    report_malformed_csv(error)
    []
  end

  def headers
    @headers ||= (CSV.parse_line(first_line, col_sep:) || []).compact_blank.map(&:downcase)
  end

  private

  attr_reader :file, :team, :errors

  def valid_file?
    if file.nil?
      errors.add(:file, :blank)
    else
      errors.add(:file, :invalid_size) if file.size.zero? || file.size > MAX_FILE_SIZE
      errors.add(:file, :invalid_format) unless file.original_filename.to_s.ends_with?(".csv") && ALLOWED_CONTENT_TYPES.include?(file.content_type)
      errors.add(:file, :invalid_headers) unless valid_headers?
    end
    errors[:file].none?
  end

  def valid_headers?
    (REQUIRED_HEADERS - headers).empty?
  rescue StandardError
    false
  end

  def first_line
    @first_line ||= File.open(file.path, &:gets)&.strip&.sub(BOM, "") || ""
  end

  def col_sep
    SUPPORTED_SEPARATORS.max_by { |sep| first_line.count(sep) }
  rescue StandardError
    SUPPORTED_SEPARATORS.first
  end

  def normalize_url(raw_url, line_number)
    parsed_url = Link.parse(raw_url)
    raise Addressable::URI::InvalidURIError.new(raw_url) if parsed_url.relative?

    Link.normalize(parsed_url)
  rescue Addressable::URI::InvalidURIError => error
    report_invalid_url(error, raw_url, line_number)
    nil
  end

  def report_malformed_csv(error)
    Rails.logger.warn(
      "csv_import_malformed_csv " \
        "team_id=#{team&.id} " \
        "filename=#{file&.original_filename} " \
        "error_class=#{error.class.name} " \
        "error_message=#{error.message}"
    )
    errors.add(:file, :malformed_csv)
  end

  def report_invalid_url(error, raw_url, line_number)
    Rails.logger.warn(
      "csv_import_invalid_url " \
        "team_id=#{team&.id} " \
        "filename=#{file&.original_filename} " \
        "line_number=#{line_number} " \
        "raw_url=#{raw_url} " \
        "error_class=#{error.class.name} " \
        "error_message=#{error.message}"
    )
    errors.add(:file, :invalid_row_url, line_number:, url: raw_url)
  end

  def merge_site_data!(sites_by_url, url, row)
    site_data = sites_by_url[url] ||= { "url" => url, "tag_names" => [] }
    site_data["tag_names"] = (site_data["tag_names"] + Tag.parse_names(row["tags"])).uniq
  end
end
