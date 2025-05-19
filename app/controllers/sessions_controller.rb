class SessionsController < ApplicationController
  allow_unauthenticated_access only: [:new, :create]

  def new
  end

  def create
    if user = User.find_by(params.permit(:provider, :uid))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_path, alert: Session.human(:login_failed)
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path
  end
end
