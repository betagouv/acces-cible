require "rails_helper"

RSpec.describe ApplicationExport do
  let(:relation) { Site.all }
  let(:concrete_export_class) do
    Class.new(ApplicationExport) do
      const_set(:EXTENSION, "test")

      def attributes
        {
          "Name" => :name,
          "URL" => :url,
          "Nested" => [:audit, :completed_at]
        }
      end
    end
  end
  let(:export) { concrete_export_class.new(relation) }

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
    subject(:result) { export.serialize(site) }

    let(:site) { build(:site, name: "Test Site", audits: [audit]) }
    let(:audit) { build(:audit, completed_at:, url: "https://test.com/") }
    let(:completed_at) { Time.zone.parse("2024-01-01 12:00:00") }

    it "serializes simple and nested attributes" do
      expect(result).to eq(["Test Site", "https://test.com/", completed_at])
    end

    context "when a chained method returns nil" do
      it "returns nil" do
        allow(site).to receive(:audit).and_return(nil)
        expect(result[2]).to be_nil
      end
    end
  end
end
