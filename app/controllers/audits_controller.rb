class AuditsController < ApplicationController
  include AuditsFiltering
  before_action :set_site, only: [:create, :show]

  INDEX_COLUMNS = {
    main_results: %w[compliance_rate declared_level legal_obligations declaration_quality],
    legal_obligations: %w[accessibility_page accessibility_mention schema plan],
    declaration_quality: %w[declaration_date standard auditor law_article contact declaration_format schema_quality plan_quality],
    automated_tests: %w[automated_tests_result automated_tests_applicable automated_tests_passed automated_tests_inapplicable],
    meta: %w[reachable evaluator organization_label last_audit_at tags]
  }.freeze
  DEFAULT_INDEX_COLUMNS = %w[reachable compliance_rate declared_level legal_obligations declaration_quality  evaluator organization_label last_audit_at tags].freeze

  # GET /audits
  def index
    params[:sort] ||= { last_audited_at: AuditsFiltering::DEFAULT_DIRECTION }
    @displayed_columns = session[:audits_columns] || DEFAULT_INDEX_COLUMNS
    @tags = current_user.team.tags.in_alphabetical_order
    @pagy, @audits = pagy(scoped_audits.displayable)
  end

  # PATCH /audits/columns
  def columns
    session[:audits_columns] = params.expect(columns: []) & INDEX_COLUMNS.values.flatten
    redirect_back_or_to audits_path, status: :see_other
  end

  # POST /sites/1/audits
  def create
    @audit = @site.audit!(user: current_user)
    if @audit.persisted?
      redirect_to @site, notice: t(".notice")
    else
      render "sites/show", status: :unprocessable_entity
    end
  end

  # GET /sites/1/audits/1
  def show
    @audit = @site.audits.displayable.find(params[:id])
    @title = @site.normalized_url
  end

  private

  def set_site
    @site = current_user.team.sites.preloaded.friendly.find(params.expect(:site_id))
  end
end
