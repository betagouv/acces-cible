class ScheduleProcessAuditJobs < ActiveRecord::Migration[8.0]
  def change
    say_with_time "Scheduling ProcessAuditJob for pending audits" do
      Audit.pending.find_each(&:schedule)
    end
  end
end
