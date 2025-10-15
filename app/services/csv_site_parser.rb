class CsvSiteParser
  require "csv"

  BOM = /^\xEF\xBB\xBF/
  SUPPORTED_SEPARATORS = [",", ";"].freeze

  def initialize(file)
    @file = file
  end

  def parse_data!
    sites_by_url = {}

    CSV.foreach(@file.path, headers: true, encoding: "bom|utf-8", col_sep: detect_col_sep) do |row|
      row = row.to_h.transform_keys { |header| header.to_s.downcase }

      url = Link.normalize(row["url"]).to_s
      name = row["nom"] || row["name"]
      tag_names = row["tags"].present? ? row["tags"].split(",").map(&:strip).compact_blank.uniq : []

      if sites_by_url[url]
        sites_by_url[url]["tag_names"] = (sites_by_url[url]["tag_names"] + tag_names).uniq
      else
        sites_by_url[url] = {
          "url" => url,
          "name" => name,
          "tag_names" => tag_names
        }
      end
    end

    sites_by_url.values
  end

  def headers
    @headers ||= (CSV.parse_line(first_line, col_sep: detect_col_sep) || []).compact_blank.map(&:downcase)
  end

  private

  def first_line
    @first_line ||= File.open(@file.path, &:gets)&.strip&.sub(BOM, "") || ""
  end

  def detect_col_sep
    SUPPORTED_SEPARATORS.max_by { |sep| first_line.count(sep) }
  rescue StandardError
    SUPPORTED_SEPARATORS.first
  end
end
