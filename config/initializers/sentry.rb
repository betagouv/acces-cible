Sentry.init do |config|
  return unless Rails.env.production?

  config.dsn = Rails.application.credentials.dig(:sentry, :dsn)
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.environment = :staging if Rails.application.staging?
  config.release = ENV["CONTAINER_VERSION"]

  # Enable structured logging
  # By default, Sentry captures :active_record, :action_controller
  # https://docs.sentry.io/platforms/ruby/guides/rails/logs/#structured-logging-subscribers
  # This config enables :active_job too
  config.enable_logs = true
  config.rails.structured_logging.subscribers = {
    active_record: Sentry::Rails::LogSubscribers::ActiveRecordSubscriber,
    action_controller: Sentry::Rails::LogSubscribers::ActionControllerSubscriber,
    active_job: Sentry::Rails::LogSubscribers::ActiveJobSubscriber,
  }

  # Environment-specific performance and debugging settings
  if Rails.application.staging?
    config.traces_sample_rate = 0.1
    config.profiles_sample_rate = 0.8
    config.include_local_variables = true
  else
    config.traces_sample_rate = 0.005
    config.profiles_sample_rate = 0.5
  end

  # Use new Ruby profiler (requires gem "vernier" in Gemfile)
  config.profiler_class = Sentry::Vernier::Profiler

  # Filter common non-actionable exceptions
  config.excluded_exceptions += %w[
    ActionController::BadRequest
    ActionController::UnknownFormat
    ActionDispatch::Http::MimeNegotiation::InvalidType
    Rack::QueryParser::InvalidParameterError
    CGI::Session::CookieStore::TamperedWithCookie
  ]

  # Add user context for authenticated requests
  config.before_send_transaction = lambda do |event, hint|
    if defined?(Current) && Current.respond_to?(:user) && Current.user
      Sentry.set_user(
        id: Current.user.id,
        email: Current.user.email
      )
    end
    event
  end
end
