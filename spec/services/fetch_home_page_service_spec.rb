# frozen_string_literal: true

require "rails_helper"

RSpec.describe FetchHomePageService do
  subject(:fetch!) { described_class.call(audit) }

  let(:audit) { create(:audit) }

  before do
    allow(Browser).to receive(:get).and_return({ body: "foobar" })
    allow(Audit).to receive(:find).with(audit.id.to_s).and_return(audit)
    allow(audit).to receive(:update_home_page!)
  end

  it "calls Browser.get with the audit URL" do
    fetch!

    expect(Browser).to have_received(:get).with(audit.url)
  end

  it "stores the home page on the audit" do
    fetch!

    expect(audit).to have_received(:update_home_page!).with("foobar")
  end
end
