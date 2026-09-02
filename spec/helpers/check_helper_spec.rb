require 'rails_helper'

RSpec.describe CheckHelper do
  let(:check) { create(:check, :accessibility_mention, state) }
  let(:state) { nil }

  describe "#status_to_badge_text" do
    subject { helper.status_to_badge_text(check) }

    context "when the check is finished" do
      let(:state) { :completed }

      context "and it responds to custom badge text" do
        before do
          def check.custom_badge_text = "foobar"
        end

        it { is_expected.to eq "foobar" }
      end
    end

    context "when the check is not finished" do
      let(:state) { :pending }

      before do
        allow(I18n)
          .to receive(:t)
                .with("check.status.pending")
                .and_return "state"
      end

      it { is_expected.to eq "state" }
    end
  end

  describe "#status_link" do
    subject { helper.status_link(check) }

    context "when then check is not finished" do
      let(:state) { :pending }

      it { is_expected.to be_nil }
    end

    context "when the check is finished" do
      let(:state) { :completed }

      context "when the badge implements the link logic" do
        before do
          def check.custom_badge_link = "link"
        end

        it { is_expected.to eq "link" }
      end
    end
  end

  describe "#status_to_badge_level" do
    subject { helper.status_to_badge_level(check) }

    [
      ["errored", :error],
      ["failed", :error],
      ["pending", :info],
      ["blocked", :info],
    ].each do |state, expected_badge_level|
      context "when the check is in the #{state} state" do
        let(:state) { state }

        it { is_expected.to eq expected_badge_level }
      end
    end

    context "when the check is in the completed state" do
      let(:state) { :completed }

      context "with a custom badge level" do
        before do
          def check.custom_badge_status = :foobar
        end

        it { is_expected.to eq :foobar }
      end

      context "without a custom badge level" do
        before do
          allow(check)
            .to receive(:respond_to?)
                  .with(:custom_badge_status)
                  .and_return false
        end

        it { is_expected.to eq :success }
      end
    end
  end

  describe "#check_badge" do
    let(:check) { create(:check, :accessibility_mention) }

    it "colours a pending check from its status level" do
      expect(helper.check_badge(check)).to have_selector(".fr-badge.fr-badge--info")
    end

    it "drops the status icon" do
      expect(helper.check_badge(check, no_icon: true)).to have_selector(".fr-badge--no-icon")
    end
  end
end
