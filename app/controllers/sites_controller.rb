class SitesController < ApplicationController
  before_action :set_site, except: :index
  before_action :redirect_old_slugs, except: [:index, :new, :create], if: :get_request?

  # GET /sites
  def index
    @pagy, @sites = pagy Site.includes(:audit)
  end

  # GET /sites/1
  def show; end

  # GET /sites/new
  def new; end

  # GET /sites/1/edit
  def edit; end

  # POST /sites
  def create
    @site = Site.find_or_create_by_url(site_params)
    if @site.save
      redirect_to @site, notice: t(".notice")
    else
      render :new, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /sites/1
  def update
    if @site.update(site_params)
      redirect_to @site, notice: t(".notice"), status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /sites/1
  def destroy
    @site.destroy!
    redirect_to sites_path, notice: t(".notice"), status: :see_other
  end

  private

  def set_site
    @site = params[:id].present? ? Site.friendly.find(params.expect(:id)) : Site.new_with_audit
  end

  def redirect_old_slugs
    redirect_to(@site, status: :moved_permanently) unless @site.slug == params[:id]
  end

  def site_params
    params.expect(site: [:url])
  end
end
