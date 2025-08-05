class SessionsController < ApplicationController
  allow_unauthenticated_access only: [:new, :omniauth]
  redirect_if_authenticated only: [:new, :omniauth]

  def new
    if request.path == auth_failure_path
      flash.now.alert = Session.human(:login_failed)
      report(message: params[:message] || "Omniauth error")
    end
  end

  def omniauth
    if user = User.from_omniauth(request.env["omniauth.auth"])
      start_new_session_for user
      redirect_to after_authentication_url, notice: t(".success")
    else
      redirect_to auth_failure_path
    end
  end

  def destroy
    terminate_session
    redirect_to login_path
  end
end
