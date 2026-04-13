SolidQueueMonitor.setup do |config|
  config.authentication_enabled = Rails.env.production?
  config.username = Rails.application.credentials.dig(:solid_queue_monitor, :username) # TODO: add it to credentials for production
  config.password = Rails.application.credentials.dig(:solid_queue_monitor, :password) # TODO: add it to credentials for production
  config.jobs_per_page = 25
  config.auto_refresh_enabled = true
  config.auto_refresh_interval = 30
end

Rails.application.config.to_prepare do
  # The gem renders inline <style>/<script> tags and also mutates inline styles from JavaScript,
  # which conflicts with the application's strict CSP. See /config/initializers/content_security_policy.rb
  SolidQueueMonitor::ApplicationController.content_security_policy false
end
