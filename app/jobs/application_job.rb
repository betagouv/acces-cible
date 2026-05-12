class ApplicationJob < ActiveJob::Base
  self.enqueue_after_transaction_commit = true # Ensure jobs enqueued during a transaction don't run if it rolls back

  queue_as :background

  # Most jobs are safe to ignore if the underlying records are no longer available
  discard_on ActiveJob::DeserializationError, ActiveRecord::RecordNotFound

  around_perform :monitor_with_sentry

  private

  def monitor_with_sentry
    transaction = Sentry.start_transaction(
      op: "queue.solid_queue",
      name: self.class.name
    )
    transaction&.set_data(:queue, queue_name)
    transaction&.set_data(:arguments, arguments)

    yield
  rescue => error
    Sentry.capture_exception(error, extra: {
      queue: queue_name,
      job_class: self.class.name,
      arguments:
    })
    raise
  ensure
    transaction&.finish
  end
end
