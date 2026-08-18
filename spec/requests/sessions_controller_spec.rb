require "rails_helper"

RSpec.describe "Sessions" do
  let(:user) { create(:user, provider: "proconnect") }
  let(:logout_state) { SecureRandom.hex(16) }

  describe "DELETE /logout" do
    subject(:logout) { delete logout_path }

    context "when the ProConnect id_token is missing" do
      before { login_as(user) }

      it "redirects to ProConnect" do
        expect { logout }.not_to change(Session, :count)

        expect(response).to redirect_to("/auth/proconnect/logout")
        expect(response).to have_http_status(:see_other)
      end
    end

    context "with the developer provider" do
      let(:user) { create(:user, provider: "developer") }

      before { login_as(user) }

      it "terminates the session locally" do
        expect { logout }.to change(Session, :count).by(-1)

        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "GET /auth/proconnect/logout/callback" do
    subject(:logout_callback) do
      get proconnect_logout_callback_path, params: { state: returned_state }
    end

    let(:returned_state) { logout_state }

    before do
      login_as(user)
      allow(SecureRandom).to receive(:hex).with(16).and_return(logout_state)
      delete logout_path
    end

    context "with a valid state" do
      it "terminates the local session and clears the browser session" do
        expect { logout_callback }.to change(Session, :count).by(-1)

        expect(response).to redirect_to(login_path)
        expect(cookies[:session_id]).to be_blank

        get proconnect_logout_callback_path, params: { state: logout_state }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with an invalid state" do
      let(:returned_state) { "invalid-state" }

      it "rejects the request and keeps the local session" do
        expect { logout_callback }.not_to change(Session, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
