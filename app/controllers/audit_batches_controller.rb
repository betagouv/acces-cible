class AuditBatchesController < ApplicationController
  # GET /audit_batches/new?step=urls
  def new
    @audit_batch = current_user.audit_batches.new(audit_batch_params)
    previous_steps = AuditBatch::STEPS.take(AuditBatch::STEPS.index(requested_step))
    @step = unfinished_step(previous_steps) || requested_step
  end

  # POST /audit_batches
  def create
    @audit_batch = current_user.audit_batches.new(audit_batch_params)

    if @audit_batch.launch
      redirect_to audits_path, notice: t(".launched", count: @audit_batch.submitted_sites.size)
    else
      @step = unfinished_step(AuditBatch::STEPS)
      render :new, status: :unprocessable_content
    end
  end

  private

  def requested_step
    step = params[:step] || AuditBatch::STEPS.first
    raise ActionController::RoutingError, "Unknown step: #{step}" unless AuditBatch::STEPS.include?(step)

    step
  end

  def unfinished_step(steps)
    steps.find { !@audit_batch.valid?(:"#{it}_step") }
  end

  def audit_batch_params
    params.fetch(:audit_batch, { kind: :manual }).permit(:kind, urls: [], site_tags: {})
  end
end
