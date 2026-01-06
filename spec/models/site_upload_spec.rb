require "rails_helper"

RSpec.describe SiteUpload do
  subject(:site_upload) { described_class.new(file:, team:) }

  let(:team) { create(:team) }
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

  describe "#save" do
    context "when the upload is valid" do
      let(:site_data) do
        [
          { "url" => "https://example.com/", "name" => "Example Site", "tag_names" => [] },
          { "url" => "https://test.com/", "name" => "Test Site", "tag_names" => [] }
        ]
      end

      it "enqueues ProcessSiteUploadJob and returns true" do
        expect(ProcessSiteUploadJob).to receive(:perform_later).with(
          site_data,
          team.id,
          []
        )

        expect(site_upload.save).to be true
      end

      it "passes tag_ids to the job" do
        site_upload.tag_ids = [1, 2, 3]

        expect(ProcessSiteUploadJob).to receive(:perform_later).with(
          site_data,
          team.id,
          [1, 2, 3]
        )

        site_upload.save
      end
    end

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
