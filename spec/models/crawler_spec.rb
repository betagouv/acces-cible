require "rails_helper"

RSpec.describe Crawler do
  let(:root_url) { "https://example.com/" }
  let(:crawler) { described_class.new(root_url) }
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
  end

  describe "#find" do
    let(:link1) { Link.new(href: "https://example.com/page1") }
    let(:link2) { Link.new(href: "https://example.com/page2") }
    let(:root_page) { instance_double(Page, internal_links: [link1, link2], title: "Root") }

    before do
      allow(Page).to receive(:new)
        .with(url: root_url, root: root_url)
        .and_return(root_page)
    end

    it "yields page and queue to the block" do
      pages = []
      queues = []

      crawler.find do |page, queue|
        pages << page
        queues << queue
        break # Stop after first page to avoid full crawl
      end

      expect(pages).to include(root_page)
      expect(queues).not_to be_empty
    end

    it "returns nil when crawl_up_to is reached" do
      limited_crawler = described_class.new(root_url, crawl_up_to: 1)
      crawl_results = limited_crawler.find { |page, _queue| page.title == "Target" }
      expect(crawl_results).to be_nil
    end

    context "when matching page exists" do
      let(:target_page) { instance_double(Page, internal_links: [], title: "Target") }

      before do
        allow(Page).to receive(:new)
          .with(url: link1.href, root: root_url)
          .and_return(target_page)
      end

      it "returns the first matching page and logs progress" do
        expect(Rails.logger).to receive(:info).twice # root + matching page
        page = crawler.find { |page, _queue| page.title == "Target" }
        expect(page).to eq(target_page)
      end
    end

    context "when no matching page exists" do
      before do
        allow(Page).to receive(:new)
          .with(url: anything, root: root_url)
          .and_return(instance_double(Page, internal_links: [], title: "Wrong"))
      end

      it "returns nil and crawls unique pages only" do
        expect(Page).to receive(:new)
          .exactly(3).times # root + 2 unique links
          .and_return(instance_double(Page, internal_links: [link1, link2], title: "Wrong"))

        result = crawler.find { |page, _queue| page.title == "Target" }
        expect(result).to be_nil
      end
    end
  end
end
