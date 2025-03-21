class SitesController < ApplicationController
  before_action :set_site, except: [:index, :create]
  before_action :redirect_old_slugs, except: [:index, :new, :create], if: :get_request?

  # GET /sites
  def index
    sites = Site.includes(:audit).sort_by(params)
    respond_to do |format|
      format.html { @pagy, @sites = pagy sites }
      format.csv  { send_data sites.to_csv, filename: sites.to_csv_filename }
    end
  end

  # GET /sites/1
  def show
    @audit = @site.audit
  end

  # GET /sites/new
  def new; end

  # GET /sites/1/edit
  def edit; end

  # POST /sites
  def create
    if params.dig(:site, :file)
      @upload = SiteUpload.new(params.expect(site: [:file]))
      if @upload.save
        ScheduleChecksJob.perform_later
        return redirect_to sites_path, notice: t(".uploaded", count: @upload.sites.length)
      end
    else
      @site = Site.find_or_create_by_url(site_params)
      if @site.persisted?
        @site.audit.schedule if @site.audit.pending?
        return redirect_to @site, notice: t(".notice")
      end
    end
    render :new, status: :unprocessable_entity
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
    @site = params[:id].present? ? Site.friendly.find(params.expect(:id)) : Site.new
  end

  def redirect_old_slugs
    redirect_to(@site, status: :moved_permanently) unless @site.slug == params[:id]
  end

  def site_params
    params.expect(site: [:url])
  end
end
