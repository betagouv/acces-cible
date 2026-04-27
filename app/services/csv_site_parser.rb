class CsvSiteParser
  require "csv"

  BOM = /^\xEF\xBB\xBF/
  FIRST_DATA_ROW_NUMBER = 2 # Row 1 contains CSV headers
  SUPPORTED_SEPARATORS = [",", ";"].freeze

  def initialize(file:, team:, errors:)
    @file = file
    @team = team
    @errors = errors
  end

  def parse_data!
    sites_by_url = {}

    CSV.foreach(file.path, headers: true, encoding: "bom|utf-8", col_sep:).with_index(FIRST_DATA_ROW_NUMBER) do |row, line_number|
      row = row.to_h.transform_keys { |header| header.to_s.downcase }

      raw_url = row["url"].to_s.strip
      next if raw_url.empty?

      url = normalize_url(raw_url, line_number)
      next unless url

      merge_site_data!(sites_by_url, url, row)
    end

    sites_by_url.values
  rescue CSV::MalformedCSVError => error
    Rails.logger.warn(
      "site_upload_malformed_csv " \
      "team_id=#{team&.id} " \
      "filename=#{file&.original_filename} " \
      "error_class=#{error.class.name} " \
      "error_message=#{error.message}"
    )
    errors.add(:file, :malformed_csv)
    []
  end

  def headers
    @headers ||= (CSV.parse_line(first_line, col_sep:) || []).compact_blank.map(&:downcase)
  end

  private

  attr_reader :file, :team, :errors

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
    raise Link::InvalidUriError.new(raw_url) if parsed_url.relative?

    Link.normalize(parsed_url)
  rescue Link::InvalidUriError => error
    Rails.logger.warn(
      "site_upload_invalid_url " \
      "team_id=#{team&.id} " \
      "filename=#{file&.original_filename} " \
      "line_number=#{line_number} " \
      "raw_url=#{raw_url} " \
      "error_class=#{error.class.name} " \
      "error_message=#{error.message}"
    )
    errors.add(:file, :invalid_row_url, line_number:, url: raw_url)
    nil
  end

  def merge_site_data!(sites_by_url, url, row)
    name = extract_name(row)
    site_data = sites_by_url[url] || build_site_data(url, row)
    site_data["tag_names"] = (site_data["tag_names"] + extract_tag_names(row)).uniq
    site_data["name"] = name if name.present?
    sites_by_url[url] = site_data
  end

  def build_site_data(url, row)
    {
      "url" => url,
      "name" => extract_name(row),
      "tag_names" => []
    }
  end

  def extract_name(row)
    row["nom"] || row["name"]
  end

  def extract_tag_names(row)
    return [] if row["tags"].blank?

    row["tags"].split(",").map(&:strip).compact_blank.uniq
  end
end
