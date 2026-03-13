module ErrorHelper
  module_function

  def report(exception: nil, message: nil, &block)
    if Rails.respond_to?(:event) && Rails.event.respond_to?(:notify)
      Rails.logger.warn("DEPRECATION WARNING: ErrorHelper#report is deprecated. Use Rails.event.notify instead.")
    end

    return unless Sentry.initialized?

    raise ArgumentError, "Please provide either an exception or error message." if exception.nil? && message.nil?

    Sentry.with_scope do |scope|
      block&.call(scope)

      Sentry.capture_exception(exception) if exception
      Sentry.capture_message(message) if message
    end
  end
end
