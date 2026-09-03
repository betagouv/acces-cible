class TagsController < ApplicationController
  before_action :set_tag, only: :show
  before_action :redirect_old_slugs, only: :show

  # GET /tags
  def index
    @pagy, @tags = pagy current_user.team.tags.includes(:launched_sites).in_alphabetical_order
  end

  # POST /tags
  def create
    name = tag_params.dig(:tags_attributes, :name)
    return head :unprocessable_content if name.blank?

    tag = current_user.team.tags.find_or_create_by(name:)
    tag_ids = (tag_params[:tag_ids] || []).push(tag.id).compact
    object = template_object_klass.new(tag_ids:, team: current_user.team)

    locals = tags_form_locals.merge(object:, focus: true)

    render turbo_stream: turbo_stream.replace(locals[:id], partial: "sites/tags_form", locals:)
  end

  # GET /tags/1
  def show
    @pagy, @sites = pagy @tag.launched_sites
  end

  private

  def upload?
    params.key?(:site_upload)
  end

  def funnel_site
    @funnel_site ||= current_user.team.sites.find(params[:site_id]) if params[:site_id]
  end

  def tag_params
    scoped_params.permit(tag_ids: [], tags_attributes: :name)
  end

  def scoped_params
    if funnel_site
      params.require(:audit_batch).require(:site_tags).require(funnel_site.id.to_s)
    elsif upload?
      params.require(:site_upload)
    else
      params.require(:site)
    end
  end

  def tags_form_locals
    @tags_form_locals ||= if funnel_site
      { id: dom_id(funnel_site, :tags),
        url: tags_path(site_id: funnel_site.id),
        scope: AuditBatch.site_tags_scope(funnel_site),
        title: t("audit_batches.steps.summary.tags", site: funnel_site.normalized_url),
        collapsible: false }
    else
      { id: dom_class(template_object_klass, :tags) }
    end
  end

  def template_object_klass
    upload? ? SiteUpload : Site
  end

  def set_tag
    @tag = current_user.team.tags.includes(:site_tags, :slugs).friendly.find(params[:id])
  end

  def redirect_old_slugs
    redirect_to(@tag, status: :moved_permanently) unless @tag.slug == params[:id]
  end
end
