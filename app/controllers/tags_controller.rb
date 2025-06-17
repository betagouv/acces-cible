class TagsController < ApplicationController
  # POST /tags
  def create
    create_params = params.require(upload? ? :site_upload : :site)
    new_tag = current_user.team.tags.find_or_create_by(name: create_params[:tags_attributes][:name])
    if new_tag.persisted?
      tag_ids = (create_params[:tag_ids] || []).push(new_tag.id).compact
      object = template_object_klass.new(tag_ids:, team: current_user.team)
      render turbo_stream: turbo_stream.replace(:site_tags, partial: "sites/tags_form", locals: { object:, focus: true })
    else
      head :unprocessable_entity
    end
  end

  private

  def upload? = params.key?(:site_upload)
  def template_object_klass = upload? ? SiteUpload : Site
end
