class TagsController < ApplicationController
  # POST /tags
  def create
    tag = current_user.team.tags.find_or_create_by(name: tag_params[:tags_attributes][:name])
    tag_ids = (site_params.fetch(:tag_ids, []).push(tag.id)).compact
    site = Site.new(team: current_user.team, tag_ids:)
    if tag.persisted?
      render turbo_stream: turbo_stream.replace(:site_tags, partial: "sites/tags_form", locals: { site:, focus: true })
    else
      head :unprocessable_entity
    end
  end

  private

  def site_params
    params.require(:site).permit(tag_ids: []) || {}
  end

  def tag_params
    params.expect(site: [tags_attributes: [:name]])
  end
end
