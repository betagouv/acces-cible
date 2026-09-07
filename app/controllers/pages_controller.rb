class PagesController < ApplicationController
  allow_unauthenticated_access
  before_action :set_check_pages, only: :help

  def home
    if authenticated?
      @title = t(".greeting", name: current_user.name)
      set_home_stats(current_user.team.audits, current_user.team.sites)
    else
      @title = t(".welcome")
      set_home_stats(Audit.all, Site.all)
    end
  end

  def help
    available_pages = @check_pages.map { |page| page[:file_name] }
    @check = params[:check] if available_pages.include?(params[:check])
  end

  private

  def set_home_stats(audits, sites)
    @audits_count = audits.count
    @audits_this_week_count = audits.where(created_at: Time.zone.today.all_week).count
    @audited_sites_count = sites.where.not(audits_count: 0).count
  end

  def set_check_pages
    files = Dir.glob(Rails.root.join("app/views/pages/checks/*.html.md"))

    @check_pages = files.map do |file_path|
      file_name = File.basename(file_path, ".html.md")
      { file_name:, title: t("checks.#{file_name}.type") }
    end.sort_by { |page| page[:title] }
  end
end
