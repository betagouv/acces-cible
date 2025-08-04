class ScheduleAuditsJob < ApplicationJob
  def perform
    Audit.pending.find_each do |audit|
      audit.schedule
    end
  end
end
