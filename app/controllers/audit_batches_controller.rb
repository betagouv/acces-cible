class AuditBatchesController < ApplicationController
  before_action :set_audit_batch, only: [:show_step, :update_step, :destroy]
  before_action :set_step, only: [:new, :create, :show_step, :update_step]
  before_action :set_title, only: [:show_step, :update_step]
  before_action :enforce_progression, only: [:show_step, :update_step]

  # GET /audit_batches/new
  def new
    @audit_batch = current_user.audit_batches.new(kind: :manual)
  end

  # POST /audit_batches
  def create
    @audit_batch = current_user.audit_batches.new(step_params)

    if @audit_batch.save(context: step_context)
      redirect_to next_step_path
    else
      render :new, status: :unprocessable_content
    end
  end

  # GET /audit_batches/1/steps/urls
  def show_step; end

  # PATCH /audit_batches/1/steps/urls
  def update_step
    @audit_batch.assign_attributes(step_params)

    if @audit_batch.save(context: step_context)
      last_step? ? launch : redirect_to(next_step_path)
    else
      render :show_step, status: :unprocessable_content
    end
  end

  # DELETE /audit_batches/1
  def destroy
    @audit_batch.abandon!
    redirect_to sites_path, notice: t(".cancelled"), status: :see_other
  end

  private

  def set_audit_batch
    @audit_batch = current_user.audit_batches.draft.find(params.expect(:id))
  end

  def set_step
    @step = params[:step] || AuditBatch::STEPS.first
    raise ActiveRecord::RecordNotFound unless AuditBatch::STEPS.include?(@step)
  end

  def set_title
    @title = t("audit_batches.new.title")
  end

  def enforce_progression
    return if @audit_batch.step_reachable?(@step)

    redirect_to step_audit_batch_path(@audit_batch, @audit_batch.first_incomplete_step)
  end

  def step_context
    :"#{@step}_step"
  end

  def last_step?
    @audit_batch.next_step(@step).nil?
  end

  def launch
    @audit_batch.launched!
    redirect_to sites_path, notice: t(".launched", count: @audit_batch.audits.size)
  end

  def next_step_path
    step_audit_batch_path(@audit_batch, @audit_batch.next_step(@step))
  end

  def step_params
    case @step
    when "method" then params.expect(audit_batch: [:kind])
    when "urls" then params.expect(audit_batch: [urls: []])
    when "summary" then params.expect(audit_batch: [site_tags: {}])
    else {}
    end
  end
end
