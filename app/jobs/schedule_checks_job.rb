class ScheduleChecksJob < ApplicationJob
  def perform
    Check.to_schedule.prioritized.find_each do |check|
      Check.transaction do
        RunCheckJob.set(wait_until: check.run_at).perform_later(check)
        check.update(scheduled: true)
      end
    end
  end
end
