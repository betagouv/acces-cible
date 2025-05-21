class SessionsController < ApplicationController
  allow_unauthenticated_access only: [:new, :omniauth]
  redirect_if_authenticated only: [:new, :omniauth]

  def new
    flash.now.alert = Session.human(:login_failed) if request.path == auth_failure_path
  end

  def omniauth
    if user = User.from_omniauth(request.env["omniauth.auth"])
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to auth_failure_path
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end
end
