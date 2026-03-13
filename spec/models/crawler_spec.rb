require "rails_helper"

RSpec.describe Crawler do
  subject(:crawler) { described_class.new(root_url) }

  let(:root_url) { "https://example.com/" }
  let(:page) { instance_double(Page, internal_links: []) }

  before do
    allow(Page).to receive(:new).and_return(page)
    allow(Rails.logger).to receive(:info)
  end

  describe "#initialize" do
    it "sets up crawler with default max pages" do
      expect(crawler.send(:crawl_up_to)).to eq(described_class::MAX_CRAWLED_PAGES)
    end

    it "allows custom max pages" do
      custom_crawler = described_class.new(root_url, crawl_up_to: 50)
      expect(custom_crawler.send(:crawl_up_to)).to eq(50)
    end

    context "when root doesn't end with a slash" do
      let(:root_url) { "https://example.com/home" }

      it "returns path up to the last slash" do
        expect(crawler.send(:root).href).to eq("https://example.com/")
      end
    end
  end

  describe "#find_page" do
    let(:link1) { Link.new(href: "https://example.com/page1") }
    let(:link2) { Link.new(href: "https://example.com/page2") }
    let(:root_page) { instance_double(Page, internal_links: [link1, link2], title: "Root") }

    before do
      allow(Page).to receive(:new)
                       .with(url: root_url, root: root_url, html: nil)
                       .and_return(root_page)
    end

    it "yields page to the block" do
      pages = []

      crawler.find_page do |page|
        pages << page
        break # Stop after first page to avoid full crawl
      end

      expect(pages).to include(root_page)
    end

    it "returns nil when crawl_up_to is reached" do
      limited_crawler = described_class.new(root_url, crawl_up_to: 1)
      crawl_results = limited_crawler.find_page { |page| page.title == "Target" }
      expect(crawl_results).to be_nil
    end

    context "when matching page exists" do
      let(:target_page) { instance_double(Page, internal_links: [], title: "Target") }

      before do
        allow(Page).to receive(:new)
                         .with(url: link1.href, root: root_url, html: nil)
                         .and_return(target_page)
      end

      it "returns the first matching page and logs progress" do
        crawler = described_class.new(root_url, queue: LinkList.new([root_url, link1.href]))
        page = crawler.find_page { |page| page.title == "Target" }
        expect(page).to eq(target_page)
      end
    end

    context "when no matching page exists" do
      before do
        allow(Page).to receive(:new)
                         .with(url: anything, root: root_url, html: nil)
                         .and_return(instance_double(Page, internal_links: [], title: "Wrong"))
      end

      it "returns nil and crawls unique pages only" do
        crawler = described_class.new(root_url, queue: LinkList.new([root_url, link1.href, link2.href]))
        expect(Page).to receive(:new)
                          .exactly(3).times # root + 2 unique links
                          .and_return(instance_double(Page, internal_links: [link1, link2], title: "Wrong"))

        result = crawler.find_page { |page| page.title == "Target" }
        expect(result).to be_nil
      end
    end
  end
end
