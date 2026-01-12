class SitesController < ApplicationController
  include ActionController::Live
  before_action :set_site, only: [:show, :edit, :update, :destroy]
  before_action :set_sites, only: :destroy_all
  before_action :redirect_old_slugs, except: [:index, :new, :create], if: :get_request?

  # GET /sites
  def index
    params[:sort] ||= { checked_at: :desc }
    @sites = current_user.sites
    @tags = current_user.team.tags.in_alphabetical_order
    respond_to do |format|
      format.html do
        @pagy, @sites = pagy @sites.preloaded.filter_by(params).order_by(params), limit: pagy_limit
      end
      format.csv do
        set_csv_headers
        stream_csv
      end
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
      redirect_to @site, notice:
    else
      render :new, status: :unprocessable_content
    end
  end

  # POST /sites/upload
  def upload
    @upload = SiteUpload.new(site_upload_params)
    if @upload.save
      redirect_to sites_path, notice: t(".started")
    else
      render :new, status: :unprocessable_content
    end
  end

  # PATCH/PUT /sites/1
  def update
    if @site.update(site_params)
      redirect_to @site, notice: t(".notice"), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /sites/1
  def destroy
    @site.destroy!
    redirect_to sites_path, notice: t(".notice"), status: :see_other
  end

  # DELETE /sites
  def destroy_all
    count = @sites.count
    @sites.destroy_all
    redirect_to sites_path, notice: t(".notice", count:), status: :see_other
  end

  private

  def set_csv_headers
    response.headers["Content-Type"] = "text/csv; charset=utf-8"
    response.headers["Content-Disposition"] = "attachment; filename=#{SiteCsvExport.filename}"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["Last-Modified"] = Time.now.httpdate
  end

  def stream_csv
    SiteCsvExport.stream_csv_to(response.stream, @sites)
  ensure
    response.stream.close
  end

  def set_site
    @site = current_user
      .team
      .sites
      .preloaded
      .friendly
      .find(params.expect(:id))
  end

  def set_sites
    site_ids = params.expect(id: [])
    @sites = current_user.team.sites.where(id: site_ids)
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
