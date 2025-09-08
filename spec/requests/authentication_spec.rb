require "rails_helper"

RSpec.describe "Authentication" do
  let(:user) { create(:user) }

  describe "when browsing" do
    context "with no session" do
      it "redirects to login" do
        get authenticated_root_path
        expect(response).to redirect_to(login_path)
      end
    end

    context "with an active session" do
      before { login_as(user) }

      it "allows access with recent session" do
        get authenticated_root_path
        expect(response).to have_http_status(:success)
      end
    end

    context "with an expired session" do
      it "redirects to login when session is expired" do
        expired_session = create(:session, user:, updated_at: 2.months.ago)
        allow_any_instance_of(Authentication).to receive(:find_session_by_cookie).and_return(nil) # rubocop:disable RSpec/AnyInstance

        get authenticated_root_path
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "logout" do
    before { login_as(user) }

    it "destroys the session" do
      session = Current.session
      expect { delete logout_path }
        .to change { Session.exists?(session.id) }.to(false)
    end

    it "redirects to login" do
      delete logout_path
      expect(response).to redirect_to(login_path)
    end
  end
end
