class AuditCsvExportsController < ApplicationController
  include ActionController::Live
  include AuditsFiltering

  # GET /audits/csv_export
  def csv_export
    set_csv_headers
    AuditCsvExport.stream_csv_to(response.stream, scoped_audits.displayable)
  ensure
    response.stream.close
  end

  private

  def set_csv_headers
    response.headers["Content-Type"] = "text/csv; charset=utf-8"
    response.headers["Content-Disposition"] = "attachment; filename=#{AuditCsvExport.filename}"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["Last-Modified"] = Time.now.httpdate
  end
end
