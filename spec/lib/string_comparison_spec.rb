require "rails_helper"

RSpec.describe StringComparison do
  describe ".similar?" do
    context "with default options" do
      it "matches identical strings" do
        expect(described_class.similar?("hello", "hello")).to be true
      end

      it "does not match different strings" do
        expect(described_class.similar?("hello", "world")).to be false
      end

      it "is case sensitive by default" do
        expect(described_class.similar?("Hello", "hello")).to be false
      end

      it "handles nil values" do
        expect(described_class.similar?(nil, "hello")).to be false
        expect(described_class.similar?("hello", nil)).to be false
        expect(described_class.similar?(nil, nil)).to be false
      end
    end

    context "with case insensitive option" do
      let(:options) { { ignore_case: true } }

      it "matches same strings with different case" do
        expect(described_class.similar?("Hello", "hello", options)).to be true
        expect(described_class.similar?("WORLD", "world", options)).to be true
      end

      it "still doesn't match different strings" do
        expect(described_class.similar?("hello", "world", options)).to be false
      end
    end

    context "with partial matching" do
      let(:options) { { partial: true } }

      it "matches when one string contains the other" do
        expect(described_class.similar?("hello world", "hello", options)).to be true
        expect(described_class.similar?("hello", "hello world", options)).to be true
      end

      it "is still case sensitive by default" do
        expect(described_class.similar?("Hello world", "hello", options)).to be false
      end
    end

    context "with fuzzy matching" do
      let(:options) { { fuzzy: 0.8 } }

      it "matches strings with minor differences" do
        expect(described_class.similar?("hello", "helo", options)).to be true
        expect(described_class.similar?("address", "adress", options)).to be true
      end

      it "doesn't match strings with major differences" do
        expect(described_class.similar?("hello", "goodbye", options)).to be false
      end

      context "when fuzzy threshold is zero" do
        let(:options) { { fuzzy: 0 } }

        it "raises an ArgumentError" do
          expect { described_class.similar?("a", "b", options) }.to raise_error(ArgumentError)
        end
      end
    end

    context "with combined options" do
      let(:options) { { ignore_case: true, partial: true, fuzzy: 0.8 } }

      it "matches partial case-insensitive fuzzy strings" do
        expect(described_class.similar?("Hello world", "hello werlt", options)).to be true
        expect(described_class.similar?("Contact Information", "contact info", options)).to be true
      end
    end
  end

  describe ".similarity_ratio" do
    it "returns 0.0 when strings have nothing in common" do
      expect(described_class.similarity_ratio("abc", "DEF")).to eq(0.0)
    end

    it "returns 1.0 when strings are identical" do
      expect(described_class.similarity_ratio("same", "same")).to eq(1.0)
    end

    it "returns the similarity ratio when there is overlap" do
      expect(described_class.similarity_ratio("the quick brown fox", "jumped over the lazy dog")).to be_between(0.1, 0.2)
      expect(described_class.similarity_ratio("the quick brown fox", "the quick brown cat")).to be_between(0.8, 0.9)
    end

    it "handles nil and empty values" do
      expect(described_class.similarity_ratio(nil, "hello")).to eq(0.0)
      expect(described_class.similarity_ratio("hello", nil)).to eq(0.0)
      expect(described_class.similarity_ratio(nil, nil)).to eq(0.0)
      expect(described_class.similarity_ratio("", "")).to eq(0.0)
    end

    context "when :ignore_case is true" do
      let(:options) { { ignore_case: true } }

      it "ignores case" do
        expect(described_class.similarity_ratio("Hello", "hello", options)).to eq(1.0)
        expect(described_class.similarity_ratio("WORLD", "world", options)).to eq(1.0)
      end
    end
  end
end
