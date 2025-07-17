class CsvExport < ApplicationExport
  EXTENSION = "csv"

  def csv_options
    { col_sep: ";" }
  end

  def to_csv
    CSV.generate(**csv_options.merge(headers: true)) do |csv|
      csv << headers
      records.each do |record|
        csv << serialize(record)
      end
    end
  end
end
