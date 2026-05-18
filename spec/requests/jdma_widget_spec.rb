require "rails_helper"

RSpec.describe "JDMA widget" do
  let(:user) { create(:user) }

  before do
    allow(Rails.env).to receive(:production?).and_return(true)
  end

  it "is hidden from unauthenticated users" do
    get root_path

    expect(response.body).not_to include("jdma-modal-widget.js")
  end

  it "is shown to authenticated users" do
    login_as(user)

    get root_path

    expect(response.body).to include("jdma-modal-widget.js")
  end
end
