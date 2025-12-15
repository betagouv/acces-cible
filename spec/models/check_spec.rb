require "rails_helper"

RSpec.describe Check do
  subject(:check) { build(:check, :accessibility_mention) }

  it { should be_valid }

  describe "associations" do
    it { should belong_to(:audit) }
  end

  describe "delegations" do
    it { should delegate_method(:parsed_url).to(:audit) }
    it { should delegate_method(:human_type).to(:class) }
  end

  describe "class methods" do
    describe ".types" do
      it "returns a hash of check type symbols mapped to their classes" do
        expect(described_class.types).to be_a(Hash)
        expect(described_class.types.keys).to all(be_a(Symbol))
        expect(described_class.types.values).to all(be_a(Class))
      end
    end

    describe ".names" do
      it "returns an array of check type symbols" do
        expect(described_class.names).to match_array(Check::TYPES)
      end
    end

    describe ".classes" do
      it "returns an array of check classes" do
        expect(described_class.classes).to all(be_a(Class))
      end
    end
  end

  describe "#human_status" do
    let(:check) { create(:check, :accessibility_mention, :pending) }

    it "returns the humanized status" do
      expect(check.human_status).to eq("Planifié")
    end
  end

  describe "#root_page" do
    it "returns a Page with the audit URL" do
      audit = build(:audit, url: "https://example.com/")
      check = build(:check, :accessibility_mention, audit:)
      expect(Page).to receive(:new).with(url: "https://example.com/", root: "https://example.com/", html: nil)
      check.root_page
    end
  end

  describe "#run" do
    let(:check) { build(:check, :accessibility_mention) }

    context "when the analyze method goes well" do
      before do
        allow(check).to receive(:analyze!).and_return :result
      end

      it "saves the result" do
        expect { check.run! }.to change(check, :data).from(nil).to("result")
      end
    end

    context "when analyze! raises an error" do
      let(:error) { Ferrum::TimeoutError.new("Test error") }

      before do
        allow(check).to receive(:analyze!).and_raise(error)
      end

      it "raises a Check::RuntimeError with the correct root cause" do
        expect { check.run! }.to raise_error(Check::RuntimeError) do |err|
          expect(err.cause).to eq error
        end
      end
    end
  end

  describe "#priority" do
    context "when subclass defines PRIORITY" do
      let(:custom_check_class) do
        Class.new(described_class) do
          # Define the constant on our anonymous class
          const_set(:PRIORITY, 5)
        end
      end

      it "uses the subclass priority" do
        check = custom_check_class.new
        expect(check.priority).to eq(5)
      end
    end

    context "when subclass doesn't define PRIORITY" do
      let(:default_check_class) do
        Class.new(described_class)
        # No PRIORITY constant defined
      end

      it "defaults to Check::PRIORITY" do
        check = default_check_class.new
        expect(check.priority).to eq(described_class::PRIORITY)
      end
    end
  end

  describe "#requirements" do
    context "when subclass defines REQUIREMENTS" do
      let(:custom_check_class) do
        Class.new(described_class) do
          const_set(:REQUIREMENTS, [:reachable]) # Override REQUIREMENTS in custom subclass
        end
      end

      it "uses the subclass requirements" do
        check = custom_check_class.new
        expect(check.requirements).to eq [:reachable]
      end
    end

    context "when subclass doesn't define REQUIREMENTS" do
      let(:default_check_class) do
        Class.new(described_class) # No REQUIREMENTS override
      end

      it "defaults to Check::REQUIREMENTS" do
        check = default_check_class.new
        expect(check.requirements).to eq(described_class::REQUIREMENTS)
      end
    end
  end

  describe "#error" do
    subject { check.error }

    context "when the check has errored" do
      let(:check) { create(:check, :reachable, :errored) }

      before do
        app_path = Rails.root.to_s
        check.last_transition.update!(metadata: {
          json_class: "StandardError",
          m: "Test error message",
          b: [
            "#{app_path}/app/models/check.rb:124:in `analyze!'",
            "#{app_path}/app/models/check.rb:89:in `run!'",
            "#{app_path}/app/jobs/run_check_job.rb:12:in `perform'",
            "/lib/ruby/gems/3.4.0/gems/ferrum-0.17.1/lib/ferrum/browser.rb:245:in `command'",
            "/lib/ruby/gems/3.4.0/gems/ferrum-0.17.1/lib/ferrum/page.rb:134:in `evaluate'",
          ]
        })
      end

      it { should include(error_type: "StandardError", message: "Test error message") }
    end
  end
end
