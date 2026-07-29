require "rails_helper"

RSpec.describe SessionsController do
  let(:user) { create(:user, provider: "proconnect") }
  let(:current_session) { user.sessions.create! }
  let(:logout_state) { SecureRandom.hex(16) }

  before { cookies.signed[:session_id] = current_session.id }

  describe "DELETE #destroy" do
    context "with a ProConnect session" do
      before { session["omniauth.pc.id_token"] = "id-token" }

      it "redirects to ProConnect without touching the local session yet" do
        expect { delete :destroy }.not_to change(Session, :count)

        expect(response).to redirect_to("/auth/proconnect/logout")
        expect(response).to have_http_status(:see_other)
        expect(session["omniauth.state"]).to be_present
      end
    end

    context "when the ProConnect id_token is missing" do
      it "terminates the session locally" do
        expect { delete :destroy }.to change(Session, :count).by(-1)

        expect(response).to redirect_to(login_path)
      end
    end

    context "with the developer provider" do
      let(:user) { create(:user, provider: "developer") }

      it "terminates the session locally" do
        expect { delete :destroy }.to change(Session, :count).by(-1)

        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "GET #logout_callback" do
    before { session["omniauth.state"] = logout_state }

    context "with a valid state" do
      before { session["omniauth.pc.id_token"] = "id-token" }

      it "terminates the local session and clears the browser session" do
        expect { get :logout_callback, params: { state: logout_state } }
          .to change(Session, :count).by(-1)

        expect(response).to redirect_to(login_path)
        expect(session.to_hash).to be_empty
        expect(cookies[:session_id]).to be_blank
      end
    end

    context "with an invalid state" do
      it "rejects the request and keeps the local session" do
        expect { get :logout_callback, params: { state: SecureRandom.hex(16) } }
          .not_to change(Session, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end
end
