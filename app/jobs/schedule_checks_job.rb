class ScheduleChecksJob< ApplicationJob
  def perform
    Check.to_schedule.find_each do |check|
      Check.transaction do
        RunCheckJob.with(check).set(wait_until: check.run_at).perform_later
        check.update(scheduled: true)
      end
    end
  end
end
