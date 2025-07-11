require "rails_helper"

RSpec.describe SiteUpload do
  subject(:site_upload) { described_class.new(file:, team:) }

  let(:team) { build(:team) }
  let(:file_path) { Rails.root.join("spec/fixtures/files/sites.csv") }
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

  describe "validations" do
    it "is valid with a valid CSV file" do
      expect(site_upload).to be_valid
    end

    it "requires a file and a team" do
      site_upload = described_class.new
      expect(site_upload).not_to be_valid
      expect(site_upload.errors[:file]).not_to be_empty
      expect(site_upload.errors[:team]).not_to be_empty
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
      let(:csv_content) { "invalid_header,name\nhttps://example.com/,Example Site" }

      it "is invalid" do
        expect(site_upload).not_to be_valid
        expect(site_upload.errors.added?(:file, :invalid_headers)).to be true
      end
    end

    context "when headers are uppercase" do
      let(:csv_content) { "URL,NAME\nhttps://example.com/,Example Site" }

      it "is ignores case" do
        expect(site_upload).to be_valid
      end
    end

    context "when encoding is not UTF-8" do
      let(:encoding) { Encoding::ISO_8859_1 }
      let(:csv_content) { "URL,næme\nhttps://example.com/,Example Saïte".encode(encoding) }

      it "is invalid" do
        expect(site_upload).not_to be_valid
        expect(site_upload.errors.added?(:file, :invalid_headers)).to be true
      end
    end
  end

  describe "#parse_sites" do
    it "parses the CSV file and populates new_sites" do
      site_upload.parse_sites

      new_sites_from_csv = [
        { url: "https://example.com/", name: "Example Site", tag_ids: [], team: },
        { url: "https://test.com/", name: "Test Site", tag_ids: [], team: }
      ]
      expect(site_upload.new_sites).to eq(new_sites_from_csv)
    end

    it "handles mixed case headers" do
      csv.write("Url,Name\nhttps://example.com/,Example Site")
      csv.rewind

      site_upload.parse_sites
      expect(site_upload.new_sites.first[:url]).to eq("https://example.com/")
      expect(site_upload.new_sites.first[:name]).to eq("Example Site")
    end

    it "prefers 'nom' over 'name' when both are present" do
      csv.write("url,nom,name\nhttps://example.com/,Nom,Name")
      csv.rewind

      site_upload.parse_sites
      expect(site_upload.new_sites.first[:name]).to eq("Nom")
    end

    it "skips sites that already exist" do
      existing_site = build(:site, url: "https://example.com/")
      allow(team.sites).to receive(:find_by_url) { |args| existing_site if args[:url] == "https://example.com/" }

      site_upload.parse_sites

      expect(site_upload.existing_sites.first).to eq(existing_site)
      expect(site_upload.new_sites.first[:url]).to eq("https://test.com/")
    end
  end

  describe "#count" do
    it "returns the total number of sites" do
      site_upload.new_sites = [{ url: "https://example1.com/" }, { url: "https://example2.com/" }]
      site_upload.existing_sites = ["https://example3.com/"]

      expect(site_upload.count).to eq(3)
    end

    it "handles nil values" do
      site_upload.new_sites = nil
      site_upload.existing_sites = [{ url: "https://example.com/" }]

      expect(site_upload.count).to eq(1)
    end

    it "returns zero when no sites are present" do
      site_upload.new_sites = []
      site_upload.existing_sites = []

      expect(site_upload.count).to eq(0)
    end
  end

  describe "#tags_attributes=" do
    before { team.save }

    it "creates a new tag and adds its ID to tag_ids" do
      name = "Accessibility"
      site_upload.tags_attributes = { name: }

      expect(site_upload.tag_ids).to include(team.tags.find_by(name:).id)
    end

    it "finds existing tag and adds its ID to tag_ids" do
      existing_tag = create(:tag, name: "Existing Tag", team:)
      site_upload.tags_attributes = { name: "Existing Tag" }

      expect(site_upload.tag_ids).to include(existing_tag.id)
    end

    it "does nothing when name is blank" do
      original_tag_ids = site_upload.tag_ids.dup
      site_upload.tags_attributes = { name: "" }

      expect(site_upload.tag_ids).to eq(original_tag_ids)
    end

    it "does nothing when name is nil" do
      original_tag_ids = site_upload.tag_ids.dup
      site_upload.tags_attributes = { name: nil }

      expect(site_upload.tag_ids).to eq(original_tag_ids)
    end

    it "does nothing when name is only whitespace" do
      original_tag_ids = site_upload.tag_ids.dup
      site_upload.tags_attributes = { name: "   " }

      expect(site_upload.tag_ids).to eq(original_tag_ids)
    end
  end

  describe "#parse_sites with tag_ids" do
    let(:team) { create(:team) }
    let(:tag1) { create(:tag, name: "Tag 1", team:) }
    let(:tag2) { create(:tag, name: "Tag 2", team:) }

    before do
      site_upload.tag_ids = [tag1.id, tag2.id]
    end

    it "adds tag_ids to new sites" do
      site_upload.parse_sites

      expect(site_upload.new_sites).to all(include(tag_ids: [tag1.id, tag2.id]))
    end

    it "assigns tag_ids to existing sites" do
      existing_site = create(:site, url: "https://example.com/", team:)
      site_upload.parse_sites

      expect(site_upload.existing_sites.first.tag_ids).to contain_exactly(tag1.id, tag2.id)
    end

    it "preserves existing tag_ids on existing sites" do
      tag3 = create(:tag, name: "Tag 3", team:)
      existing_site = create(:site, url: "https://example.com/", team:, tag_ids: [tag3.id])
      site_upload.parse_sites

      expect(site_upload.existing_sites.first.tag_ids).to contain_exactly(tag1.id, tag2.id, tag3.id)
    end
  end

  describe "#save" do
    # rubocop:disable RSpec/SubjectStub
    context "when the upload is valid" do
      before do
        allow(site_upload).to receive_messages(valid?: true, new_sites: [{ url: "https://example.com/", name: "Example Site" }])
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
      let(:csv_content) { "URL,næme\nhttps://exÆmple.com/,Example Saïte".encode(encoding) }

      it "returns false" do
        expect(site_upload.save).to be false
        expect { site_upload.save }.not_to raise_error
      end
    end
  end
end
