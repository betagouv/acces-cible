class ScheduleChecksJob < ApplicationJob
  def perform
    Check.schedulable.prioritized.find_each do |check|
      check.schedule!
    end
  end
end
