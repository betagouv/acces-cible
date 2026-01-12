require "rails_helper"

RSpec.describe CsvSiteParser do
  subject(:parser) { described_class.new(file) }

  let(:csv_content) { "url,name\nhttps://example.com/,Example Site\nhttps://test.com/,Test Site" }
  let(:encoding) { Encoding::UTF_8 }
  let(:csv) do
    Tempfile.new(["sites", ".csv"], encoding:).tap do |f|
      f.write(csv_content)
      f.rewind
    end
  end
  let(:file) do
    ActionDispatch::Http::UploadedFile.new(
      filename: "sites.csv",
      type: "text/csv",
      tempfile: csv
    )
  end

  describe "#parse_data!" do
    context "with valid CSV" do
      let(:csv_content) { "url,name\nhttps://example.com/,Example Site\nhttps://test.com/,Test Site" }

      it "returns an array of site hashes" do
        result = parser.parse_data!
        expect(result).to contain_exactly({ "url" => "https://example.com/", "name" => "Example Site", "tag_names" => [] }, { "url" => "https://test.com/", "name" => "Test Site", "tag_names" => [] })
      end
    end

    context "with tags column" do
      let(:csv_content) { "url,name,tags\nhttps://example.com/,Example Site,\"tag1, tag2\"" }

      it "parses tags into an array" do
        result = parser.parse_data!
        expect(result.first["tag_names"]).to eq(["tag1", "tag2"])
      end
    end

    context "with duplicate URLs" do
      let(:csv_content) { "url,name,tags\nhttps://example.com/,Example Site,tag1\nhttps://example.com/,Example Site,tag2" }

      it "merges tag_names for duplicate URLs" do
        result = parser.parse_data!
        expect(result.length).to eq(1)
        expect(result.first["tag_names"]).to contain_exactly("tag1", "tag2")
      end
    end

    context "with nom column" do
      let(:csv_content) { "url,nom\nhttps://example.com/,Site Exemple" }

      it "uses nom as name" do
        result = parser.parse_data!
        expect(result.first["name"]).to eq("Site Exemple")
      end
    end
  end

  describe "#headers" do
    let(:csv_content) { "URL,name\nhttps://example.com/,Example Site" }

    it "returns lowercase headers" do
      expect(parser.headers).to eq(["url", "name"])
    end
  end
end
