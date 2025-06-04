class RemoveOrphanTagsJob < ApplicationJob
  def perform
    Tag.orphaned.not_recently_used.destroy_all
  end
end
