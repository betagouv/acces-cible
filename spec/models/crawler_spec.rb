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
    let(:page) { instance_double(Page, internal_links: [link1, link2], title: "Root") }

    it "returns an enumerator when no block is given" do
      expect(crawler.find).to be_an(Enumerator)
    end

    context "when matching page exists" do
      let(:target_page) { instance_double(Page, internal_links: [], title: "Target") }

      before do
        allow(Page).to receive(:new)
          .with(link1.href, root_url)
          .and_return(target_page)
      end

      it "returns the first matching page" do
        result = crawler.find { |page, _queue| page.title == "Target" }.first
        expect(result).to eq(target_page)
      end

      it "logs crawling progress" do
        expect(Rails.logger).to receive(:info).twice # root + matching page
        crawler.find { |page, _queue| page.title == "Target" }
      end

      it "respects crawl limit" do
        limited_crawler = described_class.new(root_url, crawl_up_to: 1)
        expect { limited_crawler.find { |page, _queue| page.title == "Target" } }
          .to raise_error(Crawler::NoMatchError)
      end
    end

    context "when no matching page exists" do
      before do
        allow(Page).to receive(:new)
          .with(anything, root_url)
          .and_return(instance_double(Page, internal_links: [], title: "Wrong"))
      end

      it "raises NoMatchError" do
        expect { crawler.find { |page, _queue| page.title == "Target" } }
          .to raise_error(Crawler::NoMatchError)
      end

      it "crawls unique pages only" do
        expect(Page).to receive(:new)
          .exactly(3).times # root + 2 unique links
          .and_return(instance_double(Page, internal_links: [link1, link2], title: "Wrong"))

        expect { crawler.find { |page, _queue| page.title == "Target" } }
          .to raise_error(Crawler::NoMatchError)
      end
    end

    context "when a block is given" do
      let(:link1) { Link.new(href: "https://example.com/page1") }
      let(:link2) { Link.new(href: "https://example.com/page2") }
      let(:root_page) { instance_double(Page, internal_links: [link1, link2]) }
      let(:crawled_page) { root_page }

      before do
        allow(Page).to receive(:new)
          .with(root_url, root_url)
          .and_return(root_page)
        allow(Page).to receive(:new)
          .with(anything, root_url)
          .and_return(crawled_page)
      end

      it "yields each crawled page and queue" do
        pages = []
        queues = []

        crawler.find do |page, queue|
          pages << page
          queues << queue
        end

        expect(pages).to include(root_page)
        expect(queues).not_to be_empty
      end

      it "stops when reaching crawl limit" do
        limited_crawler = described_class.new(root_url, crawl_up_to: 2)
        count = 0

        limited_crawler.find do
          count += 1
          break if count == 2
        end

        expect(count).to eq(2)
      end
    end
  end
end
