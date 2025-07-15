require "rails_helper"

RSpec.describe UsersController do
  describe "GET #show" do
    subject(:get_show) { get user_path }

    context "when user is authenticated" do
      let(:user) { create(:user) }

      before do
        login_as user
        get_show
      end

      it "returns http success" do
        expect(response).to have_http_status(:success)
      end
    end

    context "when user is not authenticated" do
      before { get_show }

      it "redirects to sign in" do
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
