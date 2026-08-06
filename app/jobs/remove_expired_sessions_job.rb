class RemoveExpiredSessionsJob < ApplicationJob
  def perform
    Session.expired.delete_all
  end
end
