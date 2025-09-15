Sentry.init do |config|
  return unless Rails.env.production?

  config.dsn = Rails.application.credentials.sentry.dsn
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.environment = :staging if Rails.application.staging?
  config.release = ENV["CONTAINER_VERSION"]

  config.before_send = lambda do |event, hint|
    # Remove server_name from the event so it doesn't affect grouping
    event.server_name = nil

    # Filter sensitive data using Rails parameter filtering
    filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
    event.extra = filter.filter(event.extra) if event.extra
    event.user = filter.filter(event.user) if event.user
    event.contexts = filter.filter(event.contexts) if event.contexts

    event
  end

  # Environment-specific performance and debugging settings
  if Rails.application.staging?
    config.traces_sample_rate = 0.1
    config.profiles_sample_rate = 0.8
    config.include_local_variables = true
  else
    config.traces_sample_rate = 0.005
    config.profiles_sample_rate = 0.5
  end

  config.profiler_class = Sentry::Vernier::Profiler

  # Enable SQL query performance monitoring
  config.enable_tracing = true
end
