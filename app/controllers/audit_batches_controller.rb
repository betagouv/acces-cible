class AuditBatchesController < ApplicationController
  before_action :set_audit_batch

  # GET /audit_batches/new
  def new
    set_step(AuditBatch::STEPS.first)
  end

  # POST /audit_batches
  def create
    if params[:requested_step]
      set_step(requested_step)
      render :new
    elsif @audit_batch.launch
      redirect_to audits_path, notice: t(".launched", count: @audit_batch.submitted_sites.size)
    else
      set_step("urls")
      render :new, status: :unprocessable_content
    end
  end

  private

  def set_audit_batch
    @audit_batch = current_user.audit_batches.new(audit_batch_params)
  end

  def set_step(step)
    @step = step
    @step = "urls" if @step.in?(%w[summary checks]) && @audit_batch.invalid?(:urls_step)
    @previous_step = AuditBatch::STEPS[AuditBatch::STEPS.index(@step) - 1] unless @step == AuditBatch::STEPS.first
    @next_step = AuditBatch::STEPS[AuditBatch::STEPS.index(@step) + 1]

    case @step
    when "urls" then @sites = @audit_batch.submitted_sites.presence || [Site.new]
    when "summary"
      @pagy, @sites = pagy(@audit_batch.submitted_sites)
      @tags = current_user.team.tags.in_alphabetical_order.load
    end
  end

  def requested_step
    raise ActionController::RoutingError, "Unknown step: #{params[:requested_step]}" unless AuditBatch::STEPS.include?(params[:requested_step])

    params[:requested_step]
  end

  def audit_batch_params
    params.fetch(:audit_batch, { kind: :manual }).permit(:kind, :file, urls: [], site_tag_names: {})
  end
end
