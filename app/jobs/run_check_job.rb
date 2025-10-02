require "json/add/exception" # required to serialize errors as JSON

class RunCheckJob < ApplicationJob
  queue_as do
    check = self.arguments.first
    check.slow? ? :slow : :default
  end

  rescue_from Check::RuntimeError do |exception|
    cleaned_exception = exception.cause.dup
    cleaned_exception.set_backtrace Rails.backtrace_cleaner.clean(exception.cause.backtrace)
    arguments.first.transition_to!(:errored, cleaned_exception.as_json)
  end

  before_perform do |job|
    check = job.arguments.first

    check.transition_to!(:running)
  end

  after_perform do |job|
    check = job.arguments.first
    state = check.data ? :completed : :failed

    check.transition_to!(state)
  end

  def perform(check)
    check.run!
  end
end
