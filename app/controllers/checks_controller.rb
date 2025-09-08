class ChecksController < ApplicationController
  def index
    @pagy, @checks = pagy checks.filter_by(params).distinct, limit: pagy_limit
  end

  def show
    @check = checks.find(params[:id])
  end

  private

  def checks = Check.includes(audit: :site).where(sites: { id: current_user.sites })
end
