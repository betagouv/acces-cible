require "json/add/exception" # required to serialize errors as JSON

class RunCheckJob < ApplicationJob
  queue_as :default

  rescue_from Check::PermanentError do |exception|
    arguments.first.transition_to!(:failed, exception.cause.as_json)
  end

  retry_on Check::RuntimeError, wait: 1.minute, attempts: Check::MAX_RETRIES do |job, exception|
    # this block runs when we're out of retries
    job.arguments.first.transition_to!(:failed, exception.cause.as_json)
  end

  before_perform do |job|
    check = job.arguments.first
    check.transition_to!(:running) if check.ready?
  end

  after_perform do |job|
    job.arguments.first.transition_to!(:completed)
  end

  def perform(check)
    check.run!
  end
end
