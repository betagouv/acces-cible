class RescheduleChecksJob < ApplicationJob
  queue_as :background

  def perform
    Check.to_retry.find_each do |check|
      check.schedule_retry!
    end
  end
end
