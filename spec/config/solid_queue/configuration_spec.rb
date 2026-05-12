# frozen_string_literal: true

require "rails_helper"

RSpec.describe SolidQueue::Configuration do
  subject(:worker_queue_settings) do
    described_class
      .new
      .configured_processes
      .filter_map { |process| process.attributes[:queues] if process.kind == :worker }
  end

  let(:standard_worker_queues) { ["default", "cable", "background"] }

  it "configures the slow worker with the Solid Queue queues key" do
    expect(worker_queue_settings.first).to eq("slow")
  end

  it "configures the standard workers with the Solid Queue queues key" do
    standard_worker_queue_settings = worker_queue_settings.drop(1)

    expect(standard_worker_queue_settings.second).to eq(standard_worker_queues)
  end
end
