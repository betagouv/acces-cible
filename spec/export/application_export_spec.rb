require "rails_helper"

RSpec.describe ApplicationExport, type: :model do
  let(:relation) { Site.all }
  let(:concrete_export_class) do
    Class.new(ApplicationExport) do
      const_set(:EXTENSION, "test")

      def attributes
        {
          "Name" => :name,
          "URL" => :url,
          "Nested" => [:audit, :checked_at]
        }
      end
    end
  end
  let(:concrete_export) { concrete_export_class.new(relation) }
  let(:export) { concrete_export }

  describe "#initialize" do
    it "sets the relation" do
      expect(export.instance_variable_get(:@relation)).to eq(relation)
    end
  end

  describe "#extension" do
    it "returns the class EXTENSION constant" do
      expect(export.extension).to eq("test")
    end

    it "raises NotImplementedError when EXTENSION is not defined" do
      export_without_extension = Class.new(described_class).new(relation)
      expect { export_without_extension.extension }.to raise_error(NotImplementedError, /must define EXTENSION constant/)
    end
  end

  describe "#filename" do
    it "generates filename with table name and timestamp" do
      allow(I18n).to receive(:l).and_return("20240101_120000")
      expect(export.filename).to eq("sites_20240101_120000.test")
    end
  end

  describe "#records" do
    it "returns find_each enumerable" do
      expect(export.records).to respond_to(:each)
    end
  end

  describe "#attributes" do
    it "raises NotImplementedError for base class" do
      base_export = described_class.new(relation)
      expect { base_export.attributes }.to raise_error(NotImplementedError)
    end
  end

  describe "#serialize" do
    let(:site) { build(:site, url: "https://test.com") }
    let(:audit) { build(:audit, checked_at: Time.zone.parse("2024-01-01 12:00:00")) }

    before do
      allow(site).to receive(:audit).and_return(audit)
    end

    it "serializes simple attributes" do
      allow(site).to receive_messages(name: "Test Site", url: "https://test.com")
      result = export.serialize(site)
      expect(result[0]).to eq("Test Site")
      expect(result[1]).to eq("https://test.com")
    end

    it "serializes nested attributes" do
      result = export.serialize(site)
      expect(result[2]).to eq(Time.zone.parse("2024-01-01 12:00:00"))
    end

    it "handles nil values in chain" do
      allow(site).to receive_messages(name: "Test Site", url: "https://test.com", audit: nil)
      result = export.serialize(site)
      expect(result[2]).to be_nil
    end
  end
end
