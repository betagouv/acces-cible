class SitesController < ApplicationController
  before_action :set_site, only: [:show, :edit, :update]
  before_action :redirect_old_slugs, only: [:show, :edit]

  # GET /sites

  # GET /sites/1
  def show
    @audits = @site.audits.displayable
  end

  # GET /sites/new
  def new; end

  # GET /sites/1/edit
  def edit; end

  # POST /sites
  def create
    normalized_url = Link.url_without_scheme_and_www(site_params[:url])
    @site = current_user.team.sites.find_by(normalized_url:)

    if @site
      @site.audit!(user: current_user)
      redirect_to @site, notice: t(".new_audit")
    else
      @site = current_user.team.sites.build(site_params)

      if @site.save
        @site.audit!(user: current_user)
        redirect_to @site, notice: t(".created")
      else
        render :new, status: :unprocessable_content
      end
    end
  end

  # PATCH/PUT /sites/1
  def update
    if @site.update(site_tags_params)
      redirect_to @site, notice: t(".notice"), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  # POST /sites/upload
  def upload
    @upload = SiteUpload.new(site_upload_params)
    if @upload.save
      redirect_to audits_path, notice: t(".started", count: @upload.count)
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def sites_scope
    current_user.team.sites.preloaded
  end

  def set_site
    @site = sites_scope.friendly.find(params.expect(:id))
  end

  def redirect_old_slugs
    redirect_to(@site, status: :moved_permanently) unless @site.slug == params[:id]
  end

  def site_params
    params.expect(site: [:url, :name, tag_ids: [], tags_attributes: [:name]])
  end

  # Only tags can be modified on an existing site
  def site_tags_params
    params.expect(site: [tag_ids: [], tags_attributes: [:name]])
  end

  def site_upload_params
    params
      .expect(site_upload: [:file, { tag_ids: [], tags_attributes: [:name] }])
      .merge(team: current_user.team, user: current_user)
  end
end
