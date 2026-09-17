class TagsController < ApplicationController
  before_action :set_tag, only: :show
  before_action :redirect_old_slugs, only: :show

  # GET /tags
  def index
    @pagy, @tags = pagy current_user.team.tags.in_alphabetical_order
  end

  # POST /tags
  def create
    name = tag_params.dig(:tags_attributes, :name)
    return head :unprocessable_content if name.blank?

    tag = current_user.team.tags.find_or_create_by(name:)
    tag_ids = (tag_params[:tag_ids] || []).push(tag.id).compact
    object = Site.new(tag_ids:, team: current_user.team)

    if funnel_site_url
      render turbo_stream: turbo_stream.replace("site_tags_#{funnel_site_url.parameterize}", partial: "audit_batches/site_tags_form", locals: { site_url: funnel_site_url, object:, focus: true })
    else
      render turbo_stream: turbo_stream.replace(dom_class(object, :tags), partial: "sites/tags_form", locals: { object:, focus: true })
    end
  end

  # GET /tags/1
  def show
    @pagy, @sites = pagy @tag.sites
  end

  private

  def funnel_site_url
    @funnel_site_url ||= params.dig(:audit_batch, :site_tags)&.keys&.first
  end

  def tag_params
    scoped_params.permit(tag_ids: [], tags_attributes: :name)
  end

  def scoped_params
    if funnel_site_url
      params.require(:audit_batch).require(:site_tags).require(funnel_site_url)
    else
      params.require(:site)
    end
  end

  def set_tag
    @tag = current_user.team.tags.includes(:site_tags, :slugs).friendly.find(params[:id])
  end

  def redirect_old_slugs
    redirect_to(@tag, status: :moved_permanently) unless @tag.slug == params[:id]
  end
end
