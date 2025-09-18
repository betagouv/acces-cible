require "json/add/exception" # required to serialize errors as JSON

class RunCheckJob < ApplicationJob
  limits_concurrency to: 1, key: ->(check) { check.audit_id }

  rescue_from Check::RuntimeError do |exception|
    cleaned_exception = exception.cause.dup
    cleaned_exception.set_backtrace Rails.backtrace_cleaner.clean(exception.cause.backtrace)
    arguments.first.transition_to!(:errored, cleaned_exception.as_json)
  end

  before_perform do |job|
    check = job.arguments.first
    check.transition_to!(:running) if check.can_transition_to?(:running)
  end

  after_perform do |job|
    check = job.arguments.first
    check.transition_to!(:completed) if check.can_transition_to?(:completed)
  end

  def perform(check)
    check.run!
  end
end
