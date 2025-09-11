Sentry.init do |config|
  return unless Rails.env.production?

  config.dsn = Rails.application.credentials.sentry.dsn
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.release = ENV["CONTAINER_VERSION"]

  config.before_send = lambda do |event, hint|
    # Remove server_name from the event so it doesn't affect grouping
    event.server_name = nil
    event
  end

  # Set tracesSampleRate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  # We recommend adjusting this value in production
  config.traces_sample_rate = 0.005
  config.profiles_sample_rate = 0.5
  config.profiler_class = Sentry::Vernier::Profiler

  config.release = ENV["CONTAINER_VERSION"] if ENV["CONTAINER_VERSION"].present?
  config.environment = :staging if Rails.application.staging?
end
