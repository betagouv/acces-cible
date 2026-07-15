RSpec.shared_examples "a privileged model" do
  subject { described_class.new(siret:) }

  context "when siret is privileged" do
    let(:siret) { Privileged::PRIVILEGED_SIRETS.first }

    it { is_expected.to be_privileged }
  end

  context "when siret is not privileged" do
    let(:siret) { "12345" }

    it { is_expected.not_to be_privileged }
  end

  context "when siret is nil" do
    let(:siret) { nil }

    it { is_expected.not_to be_privileged }
  end
end
