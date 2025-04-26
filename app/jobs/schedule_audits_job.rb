class ScheduleAuditsJob < ApplicationJob
  def perform
    Audit.to_schedule.find_each do |audit|
      audit.schedule
    end
  end
end
