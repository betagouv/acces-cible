class AuditBatchesController < ApplicationController
  before_action :set_audit_batch, only: %i[new create]

  # GET /audit_batches/new
  def new
    @audit_batch.requested_step = AuditBatch::STEPS.first
    set_step_data
  end

  # POST /audit_batches
  def create
    if params[:requested_step]
      @audit_batch.requested_step = requested_step
      set_step_data
      render :new
    elsif @audit_batch.launch!
      redirect_to @audit_batch
    else
      @audit_batch.requested_step = AuditBatch::URLS_STEP
      set_step_data
      render :new, status: :unprocessable_content
    end
  end

  # GET /audit_batches/1
  def show
    @audit_batch = current_user.audit_batches.find(params.expect(:id))
    @pagy, @audits = pagy(@audit_batch.audits.without_html.preload(:site).order(:id))
    @title = t("audit_batches.new.title")
  end

  private

  def set_audit_batch
    @audit_batch = current_user.audit_batches.new(audit_batch_params)
  end

  def set_step_data
    if @audit_batch.current_step == AuditBatch::URLS_STEP
      @sites = @audit_batch.submitted_sites.presence || [Site.new]
    elsif @audit_batch.current_step == AuditBatch::SUMMARY_STEP
      @pagy, @sites = pagy(@audit_batch.submitted_sites)
      @tags = current_user.team.tags.in_alphabetical_order.load
    end
  end

  def requested_step
    raise ActionController::RoutingError, "Unknown step: #{params[:requested_step]}" unless AuditBatch::STEPS.include?(params[:requested_step])

    params[:requested_step]
  end

  def audit_batch_params
    params.fetch(:audit_batch, { kind: :manual }).permit(:kind, :file, :run_axe_on_homepage, urls: [], site_tag_names: {})
  end
end
