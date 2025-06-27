class RemoveInactiveTeamsJob < ApplicationJob
  queue_as :default

  def perform
    Team.inactive.without_users.destroy_all
  end
end
