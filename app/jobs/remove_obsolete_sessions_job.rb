class RemoveObsoleteSessionsJob < ApplicationJob
  def perform
    Session.where(updated_at: ..Authentication::SESSION_DURATION.ago).delete_all
  end
end
