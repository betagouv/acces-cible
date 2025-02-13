class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  rescue_from ActionController::RoutingError, ActiveRecord::RecordNotFound, ActiveStorage::FileNotFoundError do
    respond_to do |format|
      format.any  { head :not_found }
      format.html { render "errors#not_found", status: :not_found }
    end
  end
  rescue_from ActiveRecord::NotNullViolation do |exception|
    respond_to do |format|
      format.any  { head :internal_server_error }
      format.html { render "errors#internal_server_error", status: :internal_server_error }
    end
  end

  private

  def get_request? = request.request_method_symbol == :get
end
