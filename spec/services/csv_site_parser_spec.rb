require "rails_helper"

RSpec.describe CsvSiteParser do
  subject(:parser) { described_class.new(file:, team:, errors:) }

  let(:team) { create(:team) }
  let(:errors) { ActiveModel::Errors.new(SiteUpload.new) }
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
    it "returns an array of site hashes" do
      expect(parser.parse_data!).to contain_exactly(
        { "url" => "https://example.com/", "name" => "Example Site", "tag_names" => [] },
        { "url" => "https://test.com/", "name" => "Test Site", "tag_names" => [] }
      )
    end

    context "with mixed case headers" do
      let(:csv_content) { "Url,Name\nhttps://example.com/,Example Site" }

      it "ignores header case" do
        expect(parser.parse_data!.first["url"]).to eq("https://example.com/")
        expect(parser.parse_data!.first["name"]).to eq("Example Site")
      end
    end

    context "when file uses semicolon separator" do
      it "parses the CSV file correctly" do
        csv.write("url;name\nhttps://example.com/;Example Site\nhttps://test.com/;Test Site")
        csv.rewind

        expected_sites_data = [
          { "url" => "https://example.com/", "name" => "Example Site", "tag_names" => [] },
          { "url" => "https://test.com/", "name" => "Test Site", "tag_names" => [] }
        ]

        expect(parser.parse_data!).to eq(expected_sites_data)
      end
    end

    context "with nom and name columns" do
      let(:csv_content) { "url,nom,name\nhttps://example.com/,Nom,Name" }

      it "prefers nom over name" do
        expect(parser.parse_data!.first["name"]).to eq("Nom")
      end
    end

    context "with tags column" do
      let(:csv_content) { "url,name,tags\nhttps://example.com/,Example Site,\"tag1, tag2\"" }

      it "parses tags into an array" do
        expect(parser.parse_data!.first["tag_names"]).to eq(["tag1", "tag2"])
      end
    end

    context "with duplicate URLs" do
      let(:csv_content) { "url,name,tags\nhttps://xn--rez-dma.fr/,Punycode Example,tag1\nhttps://rezé.fr/,UTF8 Example,tag2" }

      it "deduplicates normalized URLs and merges tags" do
        result = parser.parse_data!

        expect(result.length).to eq(1)
        expect(result.first["name"]).to eq("UTF8 Example")
        expect(result.first["tag_names"]).to contain_exactly("tag1", "tag2")
      end
    end

    context "with blank lines" do
      let(:csv_content) { "url,name\nhttps://example.com/,Example Site\n,\nhttps://test.com/,Test Site" }

      it "ignores blank URLs" do
        expect(parser.parse_data!.pluck("url")).to contain_exactly("https://example.com/", "https://test.com/")
      end
    end

    context "with invalid URLs" do
      let(:csv_content) { "url,name\nhttps://example.com/,Example Site\nhttp://,Broken\n/contact,Relative\nhttps://test.com/,Test Site" }

      it "continues parsing and collects invalid URL errors" do
        allow(Rails.logger).to receive(:warn)

        expect(parser.parse_data!.pluck("url")).to contain_exactly("https://example.com/", "https://test.com/")
        expect(errors.details[:file]).to include(error: :invalid_row_url, line_number: 3, url: "http://")
        expect(errors.details[:file]).to include(error: :invalid_row_url, line_number: 4, url: "/contact")
        expect(Rails.logger).to have_received(:warn).twice
      end
    end

    context "when CSV has nil headers" do
      let(:csv_content) { "url,name,\nhttps://example.com/,Example Site,extra_data" }

      it "handles nil headers gracefully" do
        expect { parser.parse_data! }.not_to raise_error
        expect(parser.parse_data!.first["url"]).to eq("https://example.com/")
      end
    end
  end

  describe "#headers" do
    let(:csv_content) { "URL;name\nhttps://example.com/;Example Site" }

    it "returns lowercase headers" do
      expect(parser.headers).to eq(["url", "name"])
    end
  end
end
