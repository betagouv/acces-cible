class RunCheckJob < ApplicationJob
  rescue_from Check::RuntimeError do |exception|
    error = exception.cause
    arguments.first.transition_to!(:errored, json_class: error.class.name, m: error.message, b: error.backtrace)
  end

  before_perform do |job|
    check = job.arguments.first

    check.transition_to!(check.skip? ? :skipped : :running)
  end

  after_perform do |job|
    check = job.arguments.first
    next if check.skipped?

    state = check.data ? :completed : :failed

    check.transition_to!(state)
  end

  def perform(check)
    check.run! unless check.skipped?
  end
end
