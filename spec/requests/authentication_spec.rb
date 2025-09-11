require "rails_helper"

RSpec.describe "Authentication" do
  let(:user) { create(:user) }

  describe "login" do
    subject(:login) { feature_login_as(user) }

    it "creates a session and redirects to authenticated_root" do
      expect { login }.to change(Session, :count).by(1)
      expect(response).to redirect_to(authenticated_root_path)
    end
  end

  describe "when browsing" do
    subject(:get_authenticated_root) { get authenticated_root_path }

    context "with no session" do
      it "redirects to login page" do
        get_authenticated_root
        expect(response).to redirect_to(login_path)
      end
    end

    context "with an active session" do
      before { feature_login_as(user) }

      it "allows access and touches the session" do
        session = user.sessions.last
        session.update_columns(updated_at: 1.day.ago)
        get_authenticated_root
        expect(response).to have_http_status(:success)
        expect(session.reload.updated_at).to be_within(1.minute).of(Time.current)
      end
    end

    context "with an expired session" do
      it "redirects to login page" do
        updated_at = Session::MAX_IDLE_TIME.ago + 1.day
        expired_session = create(:session, user:, updated_at:)
        allow_any_instance_of(Authentication).to receive(:find_session_by_cookie).and_return(nil) # rubocop:disable RSpec/AnyInstance

        get_authenticated_root
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "logout" do
    before { login_as(user) }

    it "destroys the session and redirects to login" do
      expect { delete logout_path }.to change(Session, :count).by(-1)
      expect(response).to redirect_to(login_path)
    end
  end
end
