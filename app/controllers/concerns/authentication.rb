module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
    helper_method :current_user
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end

    def redirect_if_authenticated(**options)
      before_action :redirect_to_authenticated_root, **options.merge({ if: :authenticated? })
    end
  end

  private

  def current_user = Current.user

  def authenticated?
    resume_session
  end

  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    Current.session ||= find_session_by_cookie
  end

  def find_session_by_cookie
    Session.find(cookies.signed[:session_id]) if cookies.signed[:session_id]
  rescue ActiveRecord::RecordNotFound
    cookies.delete(:session_id)
    nil
  end

  def request_authentication
    session[:return_to_after_authenticating] = request.url
    redirect_to login_path
  end

  def after_authentication_url
    session.delete(:return_to_after_authenticating) || root_url
  end

  def start_new_session_for(user)
    user.sessions.create!.tap do |session|
      Current.session = session
      cookies.signed.permanent[:session_id] = { value: session.id, httponly: true, same_site: :lax }
    end
  end

  def terminate_session
    Current.session.destroy
    cookies.delete(:session_id)
  end

  def redirect_to_authenticated_root
    redirect_to authenticated_root_path
  end
end
