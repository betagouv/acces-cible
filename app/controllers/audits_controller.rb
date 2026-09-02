class AuditsController < ApplicationController
  before_action :set_site

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
    @audit = @site.audits.launched.with_check_transitions.find(params[:id])
    @title = @site.normalized_url
  end

  private

  def set_site
    @site = current_user.team.sites.with_launched_audit.preloaded.friendly.find(params.expect(:site_id))
  end
end
