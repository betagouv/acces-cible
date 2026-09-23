class AuditsController < ApplicationController
  include AuditsFiltering
  before_action :set_site, only: [:create, :show]

  # GET /audits
  def index
    params[:sort] ||= { last_audited_at: AuditsFiltering::DEFAULT_DIRECTION }
    @displayed_columns = session[:audits_columns] || AuditColumns::DEFAULT
    @tags = current_user.team.tags.in_alphabetical_order
    @pagy, @audits = pagy(scoped_audits.displayable)
  end

  # PATCH /audits/columns
  def columns
    session[:audits_columns] = (AuditColumns::DEFAULT | AuditColumns::GROUPS.values.flatten) & params.expect(columns: [])
    redirect_back_or_to audits_path, status: :see_other
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
end
