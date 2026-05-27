require "rails_helper"

RSpec.describe "JDMA widget" do
  let(:user) { create(:user) }
  let(:jdma_form_url) { "https://jdma.example.test/Demarches/avis/1234?button=5678" }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("JDMA_FORM_URL").and_return(jdma_form_url)
  end

  it "is hidden from unauthenticated users" do
    get root_path

    expect(response.body).not_to include("jdma-modal-widget.js")
  end

  it "is shown to authenticated users" do
    login_as(user)

    get root_path

    expect(response.body).to include("jdma-modal-widget.js")
    expect(response.body).to include(jdma_form_url)
    expect(response.body).to include("button-problem-ghost-light.svg")
    expect(response.body).to include("Signaler un problème")
  end

  context "when JDMA_FORM_URL is missing" do
    before do
      allow(ENV).to receive(:[]).with("JDMA_FORM_URL").and_return(nil)
    end

    it "is hidden from authenticated users" do
      login_as(user)

      get root_path

      expect(response.body).not_to include("jdma-modal-widget.js")
    end
  end
end
