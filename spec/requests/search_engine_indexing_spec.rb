require "rails_helper"

RSpec.describe "Search engine indexing" do
  it "allows indexing outside staging" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.headers["X-Robots-Tag"]).to be_nil
  end

  context "when on staging" do
    before do
      allow(Rails.application).to receive(:staging?).and_return(true)
    end

    it "asks search engines not to index the page" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.headers["X-Robots-Tag"]).to eq("noindex, nofollow")
    end
  end
end
