class ApplicationController < ActionController::Base
  include Pagy::Backend

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :resource, :resource_model

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

  def resource_model
    controller_path.classify.demodulize.safe_constantize
  end

  def resource
    @resource ||= instance_variable_get(instance_variable_name)
  end

  def instance_variable_name
    @instance_variable_name ||= "@#{action_name == "index" ? controller_name : controller_name.singularize}"
  end

  def get_request? = request.request_method_symbol == :get
end
