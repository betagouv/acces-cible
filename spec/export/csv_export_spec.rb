require "rails_helper"

RSpec.describe CsvExport, type: :model do
  let(:relation) { Site.all }
  let(:concrete_export_class) do
    Class.new(CsvExport) do
      def attributes
        {
          "Name" => :name,
          "URL" => :url
        }
      end
    end
  end
  let(:export) { concrete_export_class.new(relation) }

  describe "EXTENSION" do
    it "is set to csv" do
      expect(CsvExport::EXTENSION).to eq("csv")
    end
  end

  describe "#headers" do
    it "returns attribute keys" do
      expect(export.headers).to eq(["Name", "URL"])
    end
  end

  describe "#csv_options" do
    it "returns default CSV options" do
      expect(export.csv_options).to eq({ col_sep: ";" })
    end

    it "can be overridden in subclasses" do
      custom_export_class = Class.new(CsvExport) do
        def csv_options
          { col_sep: ",", quote_char: "'" }
        end
      end
      custom_export = custom_export_class.new(relation)
      expect(custom_export.csv_options).to eq({ col_sep: ",", quote_char: "'" })
    end
  end

  describe "#to_csv" do
    let(:site1) { build(:site, url: "https://site1.com") }
    let(:site2) { build(:site, url: "https://site2.com") }

    before do
      allow(site1).to receive_messages(name: "Site 1", url: "https://site1.com")
      allow(site2).to receive_messages(name: "Site 2", url: "https://site2.com")
      allow(export).to receive(:records).and_return([site1, site2])
    end

    it "generates CSV with headers" do
      csv_output = export.to_csv
      lines = csv_output.split("\n")

      expect(lines.first).to eq("Name;URL")
    end

    it "generates CSV with semicolon separator" do
      csv_output = export.to_csv
      lines = csv_output.split("\n")

      expect(lines[1]).to include("Site 1;https://site1.com")
      expect(lines[2]).to include("Site 2;https://site2.com")
    end

    it "includes all records" do
      csv_output = export.to_csv
      lines = csv_output.split("\n")

      expect(lines.length).to eq(3) # header + 2 records
    end
  end
end
