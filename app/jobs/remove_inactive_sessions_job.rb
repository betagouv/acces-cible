class RemoveInactiveSessionsJob < ApplicationJob
  def perform
    Session.inactive.delete_all
  end
end
