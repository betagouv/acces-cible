RSpec.shared_context "with analyzer setup" do
  let(:audit) { build(:audit) }
  let(:check) { described_class.new(audit:) }
  let(:body) { "<p>Parisa Tabriz</p>" }
  let(:links) { [] }
  let(:page) { build(:page, links:, body:) }

  before do
    allow(audit).to receive(:page).with(:accessibility).and_return(page)
    allow(check).to receive(:link_between_headings).and_return(true)
    allow(Browser).to receive(:reachable?).and_return(true)
  end
end

RSpec.shared_examples "analyzes documents" do
  include_context "with analyzer setup"

  describe ".analyze!" do
    context "when there is no accessibility page" do
      it "returns nil" do
        allow(audit).to receive(:page).with(:accessibility).and_return(nil)

        expect(check.send(:analyze!)).to be_nil
      end
    end

    context "when find_link and find_text_in_main both return nil" do
      it "returns nil" do
        expect(check.send(:analyze!)).to be_nil
      end
    end

    context "when years are in link.href instead of link.text" do
      let(:link) { Link.new(href: href_with_years, text: href_text) }
      let(:links) { [link] }

      it "extracts years from href" do
        expect(check.send(:analyze!)).to include(
                                           link_url: link.href,
                                           link_text: link.text,
                                           years: href_years,
                                           reachable: true,
                                           valid_years: true
                                         )
      end
    end

    context "when years are in both link.text and link.href" do
      let(:link) { Link.new(href: href_with_years, text: text_with_years) }
      let(:links) { [link] }

      it "prefers years from link.text" do
        expect(check.send(:analyze!)).to include(years: text_years)
      end
    end
  end
end

RSpec.shared_examples "matches document text" do |text:, expected:|
  include_context "with analyzer setup"

  context "when pattern is found within links" do
    let(:link) { Link.new(href: link_href, text:) }
    let(:links) { [link] }

    it "extracts years from link #{text}" do
      expect(check.send(:analyze!)).to include(
                                         link_url: link.href,
                                         link_text: link.text,
                                         link_misplaced: false,
                                         years: expected[:years],
                                         reachable: true,
                                         valid_years: expected[:valid_years],
                                         text: nil
                                       )
    end
  end

  context "when pattern is found within body" do
    let(:body) { "<p>#{text}</p>" }

    it "extracts years from text #{text}" do
      expect(check.send(:analyze!)).to include(
                                         link_url: nil,
                                         link_text: nil,
                                         link_misplaced: nil,
                                         years: expected[:years],
                                         reachable: true,
                                         valid_years: expected[:valid_years],
                                         text:,
                                       )
    end
  end
end

RSpec.shared_examples "does not match document text" do |text:|
  include_context "with analyzer setup"

  let(:body) { "<p>#{text}</p>" }

  it "returns nil for #{text}" do
    expect(check.send(:analyze!)).to be_nil
  end
end

RSpec.shared_examples "validates years" do |years:, expected:|
  include_context "with analyzer setup"

  it "returns #{expected} for #{years}" do
    expect(check.send(:within_three_years?, years)).to eq(expected)
  end
end
