class ApplicationJob < ActiveJob::Base
  self.enqueue_after_transaction_commit = true # Ensure jobs enqueued during a transaction don't run if it rolls back

  queue_as :background

  retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  discard_on ActiveJob::DeserializationError, ActiveRecord::RecordNotFound
end
