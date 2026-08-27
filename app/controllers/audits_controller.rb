class AuditsController < ApplicationController
  include ActionController::Live
  include AuditsFiltering
  before_action :set_site, only: [:create, :show]

  # GET /audits
  def index
    params[:sort] ||= { last_audited_at: AuditsFiltering::DEFAULT_DIRECTION }
    @tags = current_user.team.tags.in_alphabetical_order
    @pagy, @audits = pagy(scoped_audits.displayable)
  end

  # GET /audits/csv_export
  def csv_export
    set_csv_headers
    AuditCsvExport.stream_csv_to(response.stream, scoped_audits(ids: params[:id] || []).displayable)
  ensure
    response.stream.close
  end

  # POST /sites/1/audits
  def create
    @audit = @site.audit!(user: current_user)
    if @audit.persisted?
      redirect_to @site, notice: t(".notice")
    else
      render "sites/show", status: :unprocessable_entity
    end
  end

  # GET /sites/1/audits/1
  def show
    @audit = @site.audits.displayable.find(params[:id])
    @title = @site.normalized_url
  end

  private

  def set_site
    @site = current_user.team.sites.preloaded.friendly.find(params.expect(:site_id))
  end

  def set_csv_headers
    response.headers["Content-Type"] = "text/csv; charset=utf-8"
    response.headers["Content-Disposition"] = "attachment; filename=#{AuditCsvExport.filename}"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["Last-Modified"] = Time.now.httpdate
  end
end
