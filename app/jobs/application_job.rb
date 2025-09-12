class ApplicationJob < ActiveJob::Base
  self.enqueue_after_transaction_commit = true # Ensure jobs enqueued during a transaction don't run if it rolls back

  queue_as :background

  retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  discard_on ActiveJob::DeserializationError, ActiveRecord::RecordNotFound

  around_perform :monitor_with_sentry

  private

  def monitor_with_sentry
    Sentry.with_transaction(
      op: "queue.solid_queue",
      name: self.class.name
    ) do |transaction|
      transaction.set_data(:queue, queue_name)
      transaction.set_data(:arguments, arguments)

      yield
    end
  rescue => error
    Sentry.capture_exception(error, extra: {
      job_class: self.class.name,
      arguments: arguments,
      queue: queue_name
    })
    raise
  end
end
