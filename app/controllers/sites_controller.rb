class SitesController < ApplicationController
  before_action :set_site, only: [:show, :edit, :update, :destroy]
  before_action :redirect_old_slugs, except: [:index, :new, :create], if: :get_request?

  # GET /sites
  def index
    params[:sort] ||= { checked_at: :desc }
    sites = current_user.sites.preloaded.filter_by(params).order_by(params)
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
    url = site_params[:url]
    @site = current_user.team.sites.find_by_url(url:) || current_user.team.sites.build
    @site.assign_attributes(site_params)
    notice = t(@site.new_record? ? ".created" : ".new_audit")
    if @site.save
      @site.audit.schedule if @site.audit.pending?
      redirect_to @site, notice:
    else
      render :new, status: :unprocessable_entity
    end
  end

  # POST /sites/upload
  def upload
    @upload = SiteUpload.new(site_upload_params)
    if @upload.save
      ScheduleAuditsJob.perform_later
      redirect_to sites_path, notice: t(".uploaded", count: @upload.count)
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
    @site = params[:id].present? ? current_user.team.sites.friendly.find(params.expect(:id)) : current_user.team.sites.build
  end

  def redirect_old_slugs
    redirect_to(@site, status: :moved_permanently) unless @site.slug == params[:id]
  end

  def site_params
    params.expect(site: [:url, :name, tag_ids: [], tags_attributes: [:name]])
  end

  def site_upload_params
    params.expect(site_upload: [:file, [tag_ids: [], tags_attributes: [:name]]]).merge(team: current_user.team)
  end
end
