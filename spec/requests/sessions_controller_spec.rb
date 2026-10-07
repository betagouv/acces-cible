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

        expect(response).to redirect_to(root_path)
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

  describe "GET /auth/proconnect/callback" do
    subject(:login) { get "/auth/proconnect/callback" }

    before do
      OmniAuth.config.mock_auth[:proconnect] = OmniAuth::AuthHash.new(
        provider: "proconnect",
        uid: "123",
        info: { email: "john.doe@example.com", name: "John Doe" },
        extra: { raw_info: { siret:, organization_label: "DINUM" } }
      )
    end

    after { OmniAuth.config.mock_auth[:proconnect] = nil }

    context "when on staging with an internal siret" do
      let(:siret) { "13002526500013" }

      before { allow(Rails.application).to receive(:staging?).and_return(true) }

      it "logs the user in" do
        expect { login }.to change(Session, :count).by(1)

        expect(response).to redirect_to(authenticated_root_url)
      end
    end

    context "when on staging with an external siret" do
      let(:siret) { "12345678901234" }

      before { allow(Rails.application).to receive(:staging?).and_return(true) }

      it "refuses the login without creating the user" do
        expect { login }.not_to change(User, :count)

        expect(Session.count).to eq(0)
        expect(response).to redirect_to(login_path)
        expect(flash[:alert]).to eq(I18n.t("sessions.omniauth.staging_restricted", url: SessionsController::PRODUCTION_URL))
      end
    end

    context "when outside staging with an external siret" do
      let(:siret) { "12345678901234" }

      it "logs the user in" do
        expect { login }.to change(Session, :count).by(1)

        expect(response).to redirect_to(authenticated_root_url)
      end
    end
  end
end
