require "rails_helper"

RSpec.describe Checks::Auditable do
  let(:check) { described_class.new }
  let(:audit) { build(:audit) }

  before do
    allow(check).to receive(:audit).and_return(audit)
    allow(audit).to receive(:home_page_snapshot).and_return(home_page_snapshot)
  end

  describe "#analyze!" do
    context "when the home page can be audited" do
      let(:home_page_snapshot) { build(:page_snapshot) }

      it "returns an empty hash" do
        expect(check.send(:analyze!)).to eq({})
      end
    end

    context "when the home page cannot be audited" do
      let(:home_page_snapshot) { build(:page_snapshot, status: 404) }

      it "returns nil" do
        expect(check.send(:analyze!)).to be_nil
      end
    end
  end
end
