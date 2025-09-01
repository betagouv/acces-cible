require "json/add/exception" # required to serialize errors as JSON

class RunCheckJob < ApplicationJob
  rescue_from Check::RuntimeError do |exception|
    arguments.first.transition_to!(:failed, exception.cause.as_json)
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
