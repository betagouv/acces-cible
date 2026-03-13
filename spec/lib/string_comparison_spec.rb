require "rails_helper"

RSpec.describe StringComparison do
  describe ".similarity_ratio" do
    it "returns 0.0 when strings are completely different" do
      expect(described_class.similarity_ratio("abc", "xyz")).to eq(0.0)
    end

    it "returns 1.0 when strings are identical" do
      expect(described_class.similarity_ratio("same", "same")).to eq(1.0)
    end

    it "returns a ratio between 0.0 and 1.0 for partial matches" do
      expect(described_class.similarity_ratio("the quick brown fox", "the quick brown cat")).to be_between(0.8, 0.9)
    end

    it "returns 0.0 when strings are empty" do
      expect(described_class.similarity_ratio("", "")).to eq(0.0)
      expect(described_class.similarity_ratio("hello", "")).to eq(0.0)
      expect(described_class.similarity_ratio("", "hello")).to eq(0.0)
    end

    it "handles nil values by converting to empty strings" do
      expect(described_class.similarity_ratio(nil, "hello")).to eq(0.0)
      expect(described_class.similarity_ratio("hello", nil)).to eq(0.0)
      expect(described_class.similarity_ratio(nil, nil)).to eq(0.0)
    end

    it "ignores case when ignore_case option is true" do
      expect(described_class.similarity_ratio("Hello", "hello", ignore_case: true)).to eq(1.0)
      expect(described_class.similarity_ratio("WORLD", "world", ignore_case: true)).to eq(1.0)
    end

    it "is case sensitive by default" do
      expect(described_class.similarity_ratio("Hello", "hello")).to be < 1.0
    end

    context "with invalid fuzzy values" do
      it "raises ArgumentError when fuzzy is zero" do
        expect { described_class.similarity_ratio("a", "b", fuzzy: 0) }.to raise_error(ArgumentError, "Fuzzy option must be greater than 0.")
      end

      it "raises ArgumentError when fuzzy is greater than 1.0" do
        expect { described_class.similarity_ratio("a", "b", fuzzy: 1.5) }.to raise_error(ArgumentError, "Fuzzy option must be 1.0 maximum")
      end
    end
  end

  describe ".match?" do
    it "calls similarity_ratio without options" do
      expect(described_class).to receive(:similarity_ratio).with("foo", "foobar", {}).and_call_original
      described_class.match?("foo", "foobar")
    end

    it "calls similarity_ratio with options" do
      expect(described_class).to receive(:similarity_ratio).with("foo", "foobar", { ignore_case: true, fuzzy: 0.9 }).and_call_original
      described_class.match?("foo", "foobar", ignore_case: true, fuzzy: 0.9)
    end
  end
end
