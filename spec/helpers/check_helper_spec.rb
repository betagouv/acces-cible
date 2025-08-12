require 'rails_helper'

RSpec.describe CheckHelper do
  let(:check) { create(:check) }

  describe "#status_to_badge_text" do
    subject { helper.status_to_badge_text(check) }

    context "when the check is finished" do
      before do
        allow(check).to receive(:passed?).and_return true
      end

      context "and it responds to custom badge text" do
        before do
          def check.custom_badge_text = "foobar"
        end

        it { should eq "foobar" }
      end
    end

    context "when the check is not finished" do
      before do
        allow(Check)
          .to receive(:human)
                .with("status.pending")
                .and_return "state"
      end

      it { should eq "state" }
    end
  end

  describe "#status_link" do
    subject { helper.status_link(check) }

    context "when then check is not finished" do
      it { should be_nil }
    end

    context "when the check is finished" do
      before do
        allow(check).to receive(:passed?).and_return true
      end

      context "when the badge implements the link logic" do
        before do
          def check.custom_badge_link = "link"
        end

        it { should eq "link" }
      end
    end
  end

  describe "#to_badge" do
    subject(:to_badge) { helper.to_badge(check) }

    before do
      allow(helper).to receive(:status_to_badge_level).with(check).and_return(:level)
      allow(helper).to receive(:status_to_badge_text).with(check).and_return(:text)
      allow(helper).to receive(:status_link).with(check).and_return(:link)
    end

    it "concatenates the other helpers" do
      expect(to_badge).to eq [:level, :text, :link]
    end
  end
end
