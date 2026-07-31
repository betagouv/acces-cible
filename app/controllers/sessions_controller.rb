class SessionsController < ApplicationController
  allow_unauthenticated_access only: [:new, :omniauth, :logout_callback]
  redirect_if_authenticated only: [:new, :omniauth]

  def new
    if request.path == auth_failure_path
      flash.now.alert = t("sessions.new.login_failed")
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
    if current_user.provider == "proconnect"
      proconnect_logout
    else
      local_logout
    end
  end

  def logout_callback
    expected_state = session["omniauth.state"]
    returned_state = params[:state].to_s

    if expected_state.present? && ActiveSupport::SecurityUtils.secure_compare(expected_state, returned_state)
      terminate_local_session if authenticated?
      reset_session
      redirect_to login_path
    else
      Rails.logger.warn("State mismatch on ProConnect logout callback")
      head :unprocessable_content
    end
  end

  private

  def proconnect_logout
    session["omniauth.state"] = SecureRandom.hex(16)
    redirect_to "/auth/proconnect/logout", status: :see_other
  end

  def local_logout
    terminate_local_session
    reset_session
    redirect_to login_path
  end
end
