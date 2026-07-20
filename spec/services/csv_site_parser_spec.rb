require "rails_helper"

RSpec.describe CsvSiteParser do
  subject(:parser) { described_class.new(file:, team:, errors:) }

  let(:team) { create(:team) }
  let(:errors) { ActiveModel::Errors.new(SiteUpload.new) }
  let(:expected_sites_data) do
    [
      { "url" => "https://example.com/", "tag_names" => [] },
      { "url" => "https://test.com/", "tag_names" => [] }
    ]
  end
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
    subject(:parsed_data) { parser.parse_data! }

    it "returns an array of site hashes" do
      expect(parsed_data).to eq(expected_sites_data)
    end

    context "with mixed case headers" do
      let(:csv_content) { "Url,\nhttps://example.com/" }

      it "ignores header case" do
        expect(parsed_data.first["url"]).to eq("https://example.com/")
      end
    end

    context "when file uses semicolon separator" do
      it "parses the CSV file correctly" do
        csv.write("url;\nhttps://example.com/;\nhttps://test.com/;")
        csv.rewind

        expect(parsed_data).to eq(expected_sites_data)
      end
    end


    context "with tags column" do
      let(:csv_content) { "url,tags\nhttps://example.com/,\"tag1, tag2\"" }

      it "parses tags into an array" do
        expect(parsed_data.first["tag_names"]).to eq(["tag1", "tag2"])
      end
    end

    context "with duplicate URLs" do
      let(:csv_content) { "url,tags\nhttps://xn--rez-dma.fr/,tag1\nhttps://rezé.fr/,tag2" }

      it "deduplicates normalized URLs and merges tags" do
        expect(parsed_data.length).to eq(1)
        expect(parsed_data.first["tag_names"]).to contain_exactly("tag1", "tag2")
      end
    end

    context "with blank lines" do
      let(:csv_content) { "url,\nhttps://example.com/\n,\nhttps://test.com/,Test Site" }

      it "ignores blank URLs" do
        expect(parsed_data.pluck("url")).to contain_exactly("https://example.com/", "https://test.com/")
      end
    end

    context "with invalid URLs" do
      let(:csv_content) { "url,\nhttps://example.com/\nhttp://,\n/contact\nhttps://test.com/" }

      it "continues parsing and collects invalid URL errors" do
        allow(Rails.logger).to receive(:warn)

        expect(parsed_data.pluck("url")).to contain_exactly("https://example.com/", "https://test.com/")
        expect(errors.details[:file]).to include(error: :invalid_row_url, line_number: 3, url: "http://")
        expect(errors.details[:file]).to include(error: :invalid_row_url, line_number: 4, url: "/contact")
        expect(Rails.logger).to have_received(:warn).twice
      end
    end

    context "when CSV has nil headers" do
      let(:csv_content) { "url,\nhttps://example.com/,extra_data" }

      it "handles nil headers gracefully" do
        expect { parsed_data }.not_to raise_error
        expect(parsed_data.first["url"]).to eq("https://example.com/")
      end
    end
  end

  describe "#headers" do
    subject(:headers) { parser.headers }

    let(:csv_content) { "URL\nhttps://example.com/" }

    it "returns lowercase headers" do
      expect(headers).to eq(["url"])
    end
  end
end
