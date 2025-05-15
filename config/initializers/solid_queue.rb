Rails.application.config.solid_queue.configure do |config|
  config.cleanup_interval = 1.day
  config.delete_finished_jobs_after = 1.month
end
