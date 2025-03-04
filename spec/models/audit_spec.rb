require "rails_helper"

RSpec.describe Audit do
  subject(:audit) { build(:audit, site: nil) }

  let(:site) { create(:site) }

  it "has a valid factory" do
    audit = build(:audit)
    expect(audit).to be_valid
  end

  describe "associations" do
    it { is_expected.to belong_to(:site).touch(true) }

    Check.names.each do |name|
      it { is_expected.to have_one(name).dependent(:destroy) }
    end
  end

  describe "validations" do
    it { is_expected.to allow_value("https://example.com").for(:url) }
    it { is_expected.not_to allow_value("not-a-url").for(:url) }
  end

  describe "normalization" do
    it "normalizes URLs" do
      audit.url = "HTTPS://EXAMPLE.COM/path/"
      expect(audit.url).to eq("https://example.com/path/")
    end
  end

  describe "enums" do
    it do
      should define_enum_for(:status)
        .validating
        .with_values(["pending", "passed", "mixed", "failed"].index_by(&:itself))
        .backed_by_column_of_type(:string)
        .with_default(:pending)
    end
  end

  describe "scopes" do
    before { site.audit.destroy }

    it ".sort_by_newest returns audits in descending order by checked_at date" do
      oldest = create(:audit, site:, checked_at: 3.days.ago)
      older = create(:audit, site:, checked_at: 2.days.ago)
      newer = create(:audit, site:, checked_at: 1.day.ago)

      expect(described_class.sort_by_newest).to eq([newer, older, oldest])
    end

    it ".sort_by_url orders by URL ignoring protocol and www" do
      gamma = create(:audit, site:, url: "https://www.gamma.com")
      alpha = create(:audit, site:, url: "https://alpha.com/path")
      beta = create(:audit, site:, url: "http://www.beta.com")

      expect(described_class.sort_by_url).to eq([alpha, beta, gamma])
    end
  end

  describe "#parsed_url" do
    it "returns a parsed and normalized URI" do
      audit.url = "https://example.com/path/"
      expect(audit.parsed_url).to be_a(URI::HTTPS)
      expect(audit.parsed_url.to_s).to eq(audit.url)
    end
  end

  describe "#url_without_scheme" do
    it "returns hostname for root path" do
      audit.url = "https://example.com"
      expect(audit.url_without_scheme).to eq("example.com")
    end

    it "returns hostname and path for non-root path" do
      audit.url = "https://example.com/path"
      expect(audit.url_without_scheme).to eq("example.com/path")
    end

    it "memoizes the result" do
      audit.url = "https://example.com"
      first_result = audit.url_without_scheme
      allow(audit).to receive(:hostname).and_return("different.com") # rubocop:disable RSpec/SubjectStub
      expect(audit.url_without_scheme).to eq(first_result)
    end
  end

  describe "#all_checks" do
    let(:audit) { build(:audit) }

    it "returns all checks, building missing ones" do
      checks = audit.all_checks
      expect(checks.size).to eq(Check.types.size)
      expect(checks.all?(&:new_record?)).to be true
    end
  end

  describe "#create_checks" do
    let(:audit) { create(:audit) }

    it "creates all check types" do
      expect(audit.create_checks.size).to eq(Check.types.size)

      Check.types.keys.each do |name|
        expect(audit.public_send(name)).to be_persisted
      end
    end
  end

  describe "#derive_status_from_checks" do
    let(:audit) { create(:audit) }

    it "sets status to pending when any check is new" do
      audit = build(:audit)
      audit.derive_status_from_checks
      expect(audit.status).to eq("pending")
    end

    it "sets status to mixed when checks have different statuses" do
      audit.all_checks.first.update!(status: :passed)
      audit.all_checks.last.update!(status: :failed)
      audit.derive_status_from_checks
      expect(audit.status).to eq("mixed")
    end

    it "sets status to match checks when all have same status" do
      audit.all_checks.each { |check| check.update(status: :passed) }
      audit.derive_status_from_checks
      expect(audit.status).to eq("passed")
    end
  end
end
