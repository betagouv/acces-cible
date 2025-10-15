class TagsController < ApplicationController
  before_action :set_tag, only: [:show, :edit, :update, :destroy]
  before_action :redirect_old_slugs, only: [:show, :edit], if: :get_request?

  # GET /tags
  def index
    @pagy, @tags = pagy current_user.team.tags.in_alphabetical_order
  end

  # POST /tags
  def create
    tag_params = params.require(upload? ? :site_upload : :site).permit(tag_ids: [], tags_attributes: :name)
    name = tag_params.dig(:tags_attributes, :name)
    return head :unprocessable_content if name.blank?

    tag = current_user.team.tags.find_or_create_by(name:)
    tag_ids = (tag_params[:tag_ids] || []).push(tag.id).compact
    object = template_object_klass.new(tag_ids:, team: current_user.team)
    frame_id = dom_class(object, :tags)
    render turbo_stream: turbo_stream.replace(frame_id, partial: "sites/tags_form", locals: { object:, focus: true })
  end

  # GET /tags/1
  def show
    @pagy, @sites = pagy @tag.sites
  end

  # GET /tags/1/edit
  def edit
  end

  # PUT/PATCH /tags/1
  def update
    if @tag.update(tag_params)
      redirect_to @tag, notice: t(".notice"), status: :see_other
    else
      render :edit, status: :unprocessable_content
    end
  end

  # DELETE /tags/1
  def destroy
    @tag.destroy!
    redirect_to tags_path, notice: t(".notice"), status: :see_other
  end

  private

  def upload? = params.key?(:site_upload)
  def template_object_klass = upload? ? SiteUpload : Site
  def tag_params = params.expect(tag: [:name])
  def set_tag = @tag = current_user.team.tags.friendly.find(params[:id])

  def redirect_old_slugs
    redirect_to(@tag, status: :moved_permanently) unless @tag.slug == params[:id]
  end
end
