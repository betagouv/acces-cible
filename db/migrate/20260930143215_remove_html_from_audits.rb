class RemoveHtmlFromAudits < ActiveRecord::Migration[8.1]
  def change
    remove_column :audits, :home_page_html, :text
    remove_column :audits, :accessibility_page_html, :text
  end
end
