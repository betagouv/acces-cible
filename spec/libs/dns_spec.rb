require "rails_helper"

RSpec.describe Dns do
  describe ".resolvable?" do
    subject(:resolvable) { described_class.resolvable?(url) }

    let(:url) { "https://example.com/" }
    let(:dns) { instance_double(Resolv::DNS) }

    before do
      allow(Resolv::DNS).to receive(:new).and_return(dns)
    end

    context "with a resolvable domain" do
      it "returns true" do
        allow(dns).to receive(:getaddress).and_return("1.2.3.4")
        expect(resolvable).to be(true)
      end
    end

    context "with an invalid URL" do
      let(:url) { "invalid-url" }

      it "returns false" do
        expect(resolvable).to be(false)
      end
    end

    context "with a non-resolvable domain" do
      it "returns false when DNS resolution fails" do
        allow(dns).to receive(:getaddress).and_raise(Resolv::ResolvError)

        expect(resolvable).to be(false)
      end

      it "returns false when DNS lookup times out" do
        allow(Timeout).to receive(:timeout).and_raise(Timeout::Error)

        expect(resolvable).to be(false)
      end
    end
  end
end
