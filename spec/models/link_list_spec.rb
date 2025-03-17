require "rails_helper"

RSpec.describe LinkList do
  subject(:list) { described_class.new(initialize_with) }

  let(:initialize_with) { nil }
  let(:link1) { Link.new(href: "https://example1.com", text: "Example 1") }
  let(:link2) { Link.new(href: "https://example2.com", text: "Example 2") }
  let(:link3) { Link.new(href: "https://example3.com", text: "Example 3") }

  describe "#initialize" do
    it "creates an empty list by default" do
      expect(list.size).to eq(0)
    end

    it "accepts initial array of links" do
      list = described_class.new(link1, link2)

      expect(list.size).to eq(2)
    end
  end

  describe "#<<" do
    it "adds a unique link to the end" do
      list << link1
      list << link2
      expect(list.to_a).to eq([link1, link2])
    end

    it "ignores duplicate links" do
      list << link1
      list << link1
      expect(list.size).to eq(1)
    end

    it "returns self for chaining" do
      expect(list << link1).to eq(list)
    end
  end

  describe "#prepend_unique" do
    it "adds a unique link to the beginning" do
      list = described_class.new(link1)
      list.prepend_unique(link2)
      expect(list.to_a).to eq([link2, link1])
    end

    it "ignores duplicate links" do
      list = described_class.new(link1)
      list.prepend_unique(link1)
      expect(list.size).to eq(1)
    end

    it "returns self for chaining" do
      expect(list.prepend_unique(link1)).to eq(list)
    end
  end

  describe "#add" do
    it "adds multiple unique links" do
      list.add(link1, link2, link3)
      expect(list.to_a).to eq([link1, link2, link3])
    end

    it "ignores duplicate links" do
      list.add(link1, link1, link2)
      expect(list.size).to eq(2)
    end

    it "returns self for chaining" do
      expect(list.add(link1, link2)).to eq(list)
    end
  end

  describe "#include?" do
    it "returns true for included links" do
      list = described_class.new(link1)
      expect(list.include?(link1)).to be true
    end

    it "returns false for non-included links" do
      list = described_class.new(link1)
      expect(list.include?(link2)).to be false
    end
  end

  describe "#shift" do
    it "removes and returns the first link" do
      list = described_class.new(link1, link2)
      expect(list.shift).to eq(link1)
      expect(list.size).to eq(1)
    end

    it "raises EmptyListError when list is empty" do
      list = described_class.new
      expect { list.shift }.to raise_error(LinkList::EmptyListError)
    end
  end

  describe "#==" do
    it "considers lists equal if they have the same links in the same order" do
      list1 = described_class.new(link1, link2)
      list2 = described_class.new(link1, link2)
      expect(list1 == list2).to be true
    end

    it "considers lists different if they have different links" do
      list1 = described_class.new(link1, link2)
      list2 = described_class.new(link1, link3)
      expect(list1).not_to eq(list2)
    end
  end

  describe "#to_a" do
    it "returns an array of hrefs" do
      list = described_class.new(link1, link2)
      expect(list.to_a).to eq(["https://example1.com/", "https://example2.com/"])
    end
  end

  describe "#each" do
    it "yields each link" do
      list = described_class.new(link1, link2)
      expect { |b| list.each(&b) }.to yield_successive_args(link1, link2)
    end

    it "returns an enumerator if no block given" do
      list = described_class.new(link1, link2)
      expect(list.each).to be_an(Enumerator)
    end
  end
end
