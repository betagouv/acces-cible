require "json/add/exception" # required to serialize errors as JSON

class RunCheckJob < ApplicationJob
  rescue_from Check::RuntimeError do |exception|
    arguments.first.transition_to!(:errored, exception.cause.as_json)
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
