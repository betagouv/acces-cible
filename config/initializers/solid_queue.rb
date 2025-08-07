Rails.application.config.solid_queue.configure do |config|
  config.delete_finished_jobs_after = 2.days
  config.cleanup_interval = 6.hours
end
