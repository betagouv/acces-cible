Sentry.init do |config|
  return unless Rails.env.production?

  config.dsn = "https://cb48a87a9a7c2f33bf362a8d91c0a594@sentry.incubateur.net/218"
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  config.before_send = lambda do |event, hint|
    # Remove server_name from the event so it doesn't affect grouping
    event.server_name = nil
    event
  end

  # Set tracesSampleRate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  # We recommend adjusting this value in production
  config.traces_sample_rate = 0.005

  config.release = ENV["CONTAINER_VERSION"] if ENV["CONTAINER_VERSION"].present?
  config.environment = :staging if ENV["APP_URL"].to_s.ends_with?("incubateur.net")
end
