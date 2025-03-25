require "rails_helper"

RSpec.describe SiteUpload do
  subject(:site_upload) { described_class.new(file:) }

  let(:file_path) { Rails.root.join("spec/fixtures/files/sites.csv") }
  let(:csv_content) { "url,name\nhttps://example.com,Example Site\nhttps://test.com,Test Site" }
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

  describe "validations" do
    it "is valid with a valid CSV file" do
      expect(site_upload).to be_valid
    end

    it "requires a file" do
      site_upload = described_class.new
      expect(site_upload).not_to be_valid
      expect(site_upload.errors[:file]).not_to be_empty
    end

    context "when file is empty" do
      let(:csv_content) { nil }

      it "is invalid" do
        expect(site_upload).not_to be_valid
        expect(site_upload.errors.added?(:file, :invalid_size)).to be true
      end
    end

    context "when file size is too large" do
      before do
        allow(file).to receive(:size).and_return(SiteUpload::MAX_FILE_SIZE + 1)
      end

      it "is invalid" do
        expect(site_upload).not_to be_valid
        expect(site_upload.errors.added?(:file, :invalid_size)).to be true
      end
    end

    context "when file format is incorrect" do
      before do
        allow(file).to receive(:content_type).and_return("application/pdf")
      end

      it "is invalid" do
        expect(site_upload).not_to be_valid
        expect(site_upload.errors.added?(:file, :invalid_format)).to be true
      end
    end

    context "when headers are invalid" do
      let(:csv_content) { "invalid_header,name\nhttps://example.com,Example Site" }

      it "is invalid" do
        expect(site_upload).not_to be_valid
        expect(site_upload.errors.added?(:file, :invalid_headers)).to be true
      end
    end

    context "when encoding is not UTF-8" do
      let(:encoding) { Encoding::ISO_8859_1 }
      let(:csv_content) { "URL,næme\nhttps://example.com,Example Saïte".encode(encoding) }

      it "is invalid" do
        expect(site_upload).not_to be_valid
        expect(site_upload.errors.added?(:file, :invalid_headers)).to be true
      end
    end
  end

  describe "#sites" do
    it "parses the CSV file and returns an array of site hashes" do
      expected_sites = [
        { url: "https://example.com", name: "Example Site" },
        { url: "https://test.com", name: "Test Site" }
      ]
      expect(site_upload.sites).to eq(expected_sites)
    end

    it "handles uppercase URL headers" do
      csv_content = "URL,name\nhttps://example.com,Example Site"
      csv.rewind
      csv.write(csv_content)
      csv.rewind

      expect(site_upload.sites.first[:url]).to eq("https://example.com")
    end

    it "skips sites that already exist" do
      existing_site_url = "https://example.com"
      allow(Site).to receive(:find_by_url).with(url: existing_site_url).and_return(true)
      allow(Site).to receive(:find_by_url).with(url: "https://test.com").and_return(nil)

      expect(site_upload.sites.length).to eq(1)
      expect(site_upload.sites.first[:url]).to eq("https://test.com")
    end
  end

  describe "#save" do
    # rubocop:disable RSpec/SubjectStub
    context "when the upload is valid" do
      before do
        allow(site_upload).to receive_messages(valid?: true, sites: [{ url: "https://example.com", name: "Example Site" }])
      end

      it "creates sites in a transaction" do
        allow(site_upload).to receive(:transaction).and_return(true)

        expect(site_upload.save).to be true
      end
    end

    context "when the upload is invalid" do
      before do
        allow(site_upload).to receive(:valid?).and_return(false)
      end

      it "returns false without attempting to create sites" do
        expect(site_upload).not_to receive(:transaction)
        expect(site_upload.save).to be false
      end
    end
    # rubocop:enable RSpec/SubjectStub

    context "when file encoding is not UTF-8" do
      let(:encoding) { Encoding::ISO_8859_1 }
      let(:csv_content) { "URL,næme\nhttps://exÆmple.com,Example Saïte".encode(encoding) }

      it "returns false" do
        expect(site_upload.save).to be false
        expect { site_upload.save }.not_to raise_error
      end
    end
  end
end
