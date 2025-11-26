class ApplicationController < ActionController::Base
  include Pagy::Backend
  include Authentication
  include ErrorHelper
  include ActionView::RecordIdentifier

  layout :layout_selector

  helper_method :resource, :resource_model

  rescue_from ActionController::RoutingError, ActiveRecord::RecordNotFound, ActiveStorage::FileNotFoundError do
    @title = t("errors.not_found.title")
    respond_to do |format|
      format.any { head :not_found }
      format.html { render "errors/not_found", status: :not_found }
    end
  end
  rescue_from ActiveRecord::NotNullViolation do |exception|
    @title = t("errors.internal_server_error.title")
    respond_to do |format|
      format.any { head :internal_server_error }
      format.html { render "errors/internal_server_error", status: :internal_server_error }
    end
  end
  rescue_from Pagy::OverflowError do |exception|
    path_without_page = [request.path, request.query_string.sub(/&?page=\d*/, "")].compact_blank.join("?")
    redirect_to path_without_page, alert: t("shared.page_unavailable")
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

  def layout_selector
    "modal" if turbo_frame_request_id == "modal" # => link with "data-turbo-frame": :modal
  end

  def get_request?
    request.request_method_symbol == :get
  end

  def pagy_limit
    Integer(params[:limit], 10, exception: false).then { it&.nonzero? }
  end
end
