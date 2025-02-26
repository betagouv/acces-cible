class AuditsController < ApplicationController
  before_action :set_site

  # POST /sites/1/audits
  def create
    @audit = @site.audit!
    if @audit.persisted?
      redirect_to @site, notice: t(".notice")
    else
      render "sites/show", status: :unprocessable_entity
    end
  end

  # GET /sites/1/audits/1
  def show
    @audit = @site.audits.find(params[:id])
    @title = @site.to_title
    render "sites/show"
  end

  private

  def set_site
    @site = Site.friendly.find(params[:site_id])
  end
end
