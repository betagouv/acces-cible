require "rails_helper"

RSpec.describe JdmaHelper do
  describe "#jdma_widget_config" do
    subject(:config) { helper.jdma_widget_config }

    context "when running in staging" do
      before do
        allow(Rails.application).to receive(:staging?).and_return(true)
        allow(Rails.env).to receive(:production?).and_return(true)
      end

      it "uses the staging widget configuration" do
        expect(config).to eq(
          form_url: "https://jedonnemonavis.numerique.gouv.fr/Demarches/avis/2229?button=4664",
          button_image: "https://jedonnemonavis.numerique.gouv.fr/static/buttons/button-remark-solid-light.svg",
          button_label: "Une remarque ?",
        )
      end
    end

    context "when running in production" do
      before do
        allow(Rails.application).to receive(:staging?).and_return(false)
        allow(Rails.env).to receive(:production?).and_return(true)
      end

      it "uses the production widget configuration" do
        expect(config).to eq(
          form_url: "https://jedonnemonavis.numerique.gouv.fr/Demarches/avis/2230?button=4666",
          button_image: "https://jedonnemonavis.numerique.gouv.fr/static/buttons/button-problem-solid-light.svg",
          button_label: "Signaler un problème",
        )
      end
    end

    context "when running outside deployed environments" do
      before do
        allow(Rails.application).to receive(:staging?).and_return(false)
        allow(Rails.env).to receive(:production?).and_return(false)
      end

      it "does not enable the widget" do
        expect(config).to be_nil
      end
    end
  end
end
