class RemoveInactiveUsersJob < ApplicationJob
  queue_as :default

  def perform
    User.inactive.destroy_all
  end
end
