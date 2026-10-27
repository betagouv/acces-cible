class AuditCsvExport
  COL_SEP = ";"
  UTF8_BOM = "\uFEFF"

  HEADERS = AuditColumns::EXPORT.map { I18n.t("audits.csv_export.columns.#{it}") }.freeze

  def self.filename
    "audits_#{I18n.l(Time.zone.now, format: :file)}.csv"
  end

  def self.stream_csv_to(output_stream, audits)
    output_stream.write(UTF8_BOM)
    output_stream.write CSV.generate_line(HEADERS, col_sep: COL_SEP)

    audits.find_each(batch_size: 200) do |audit|
      output_stream.write CSV.generate_line(row_for(audit), col_sep: COL_SEP)
    end
  end

  def self.row_for(audit)
    AuditColumns::EXPORT.map { value(audit, it) }
  end

  def self.value(audit, column)
    value = AuditColumns.value(audit, column)
    value.is_a?(Hash) ? value[:text] : value
  end
end
