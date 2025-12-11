class PagesController < ApplicationController
  allow_unauthenticated_access
  before_action :set_check_pages, only: :help

  def help
    available_pages = @check_pages.map { |page| page[:file_name] }
    @check = params[:check] if available_pages.include?(params[:check])
  end

  private

  def set_check_pages
    files = Dir.glob(Rails.root.join("app/views/pages/checks/*.html.md"))

    @check_pages = files.map do |file_path|
      file_name = File.basename(file_path, ".html.md")
      { file_name:, title: Check.human("checks.#{file_name}.type") }
    end.sort_by { |page| page[:title] }
  end
end
