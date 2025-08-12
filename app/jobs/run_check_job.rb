class RunCheckJob < ApplicationJob
  queue_as :default

  retry_on Check::RuntimeError, wait: 3.seconds, attempts: Check::MAX_RETRIES do |job, exception|
    # this block runs when we're out of retries
    job.arguments.first.transition_to!(:failed, exception)
  end

  before_perform do |job|
    check = job.arguments.first

    case check.current_state
    when "ready"
      check.transition_to!(:running)
    when "running" # retry
      check.increment!(:retry_count)
    end
  end

  after_perform do |job|
    job.arguments.first.transition_to!(:completed)
  end

  def perform(check)
    check.run!
  end
end
