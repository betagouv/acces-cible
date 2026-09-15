class SitesController < ApplicationController
  before_action :set_site, only: [:show, :edit, :update]
  before_action :redirect_old_slugs, only: [:show, :edit]

  # GET /sites/1
  def show
    @audits = @site.audits.launched.displayable
  end

  # GET /sites/1/edit
  def edit; end

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
    current_user.team.sites.with_launched_audit.preloaded
  end

  def set_site
    @site = sites_scope.friendly.find(params.expect(:id))
  end

  def redirect_old_slugs
    redirect_to(@site, status: :moved_permanently) unless @site.slug == params[:id]
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
