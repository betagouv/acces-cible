class AuditBatchesController < ApplicationController
  # GET /audit_batches/new
  def new
    @audit_batch = current_user.audit_batches.new(audit_batch_params)
    @step = AuditBatch::STEPS.first
  end

  # POST /audit_batches
  def create
    @audit_batch = current_user.audit_batches.new(audit_batch_params)

    if params[:requested_step]
      show_step
    elsif @audit_batch.launch
      redirect_to audits_path, notice: t(".launched", count: @audit_batch.submitted_sites.size)
    else
      @step = unfinished_step
      render :new, status: :unprocessable_content
    end
  end

  private

  def show_step
    @step = unfinished_step(requested_step) || requested_step
    render :new
  end

  def requested_step
    raise ActionController::RoutingError, "Unknown step: #{params[:requested_step]}" unless AuditBatch::STEPS.include?(params[:requested_step])

    params[:requested_step]
  end

  def unfinished_step(step = nil)
    previous_steps = AuditBatch::STEPS.take_while { it != step }
    previous_steps.find { !@audit_batch.valid?(:"#{it}_step") }
  end

  def audit_batch_params
    params.fetch(:audit_batch, { kind: :manual }).permit(:kind, :file, urls: [], site_tags: {})
  end
end
