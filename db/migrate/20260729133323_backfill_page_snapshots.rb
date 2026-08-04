class BackfillPageSnapshots < ActiveRecord::Migration[8.1]
  def up
    Audit.find_in_batches do |audits|
      audits.each do |audit|
        if audit.home_page_html.present?
          PageSnapshot.create!(audit:, kind: "home", requested_url: audit.home_page_url, current_url: audit.home_page_url, html: audit.home_page_html, status: 200, content_type: "text/html")
        end
        if audit.accessibility_page_html.present?
          PageSnapshot.create!(audit:, kind: "accessibility", requested_url: audit.accessibility_page_url, current_url: audit.accessibility_page_url, html: audit.accessibility_page_html, status: 200, content_type: "text/html")
        end
      end
    end
  end
end
