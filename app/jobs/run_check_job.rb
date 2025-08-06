class RunCheckJob < ApplicationJob
  queue_as :default

  retry_on Check::RuntimeError, wait: 3.seconds, attempts: Check::MAX_RETRIES do |job, exception|
    # this block runs when we're out of retries
    job.arguments.first.transition_to!(:failed, exception)
  end

  before_perform do |job|
    jobs.arguments.first.tap do |job|
      if job.in_state?(:running) # retry
        job.increment!(:retry_count)
      else
        job.transition_to!(:running)
      end
    end
  end

  after_perform do |job|
    job.arguments.first.transition_to!(:completed)
  end

  def perform(check)
    check.run
  end
end
