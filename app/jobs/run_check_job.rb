require "json/add/exception" # required to serialize errors as JSON

class RunCheckJob < ApplicationJob
  rescue_from Check::RuntimeError do |exception|
    arguments.first.transition_to!(:failed, exception.cause.as_json)
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
