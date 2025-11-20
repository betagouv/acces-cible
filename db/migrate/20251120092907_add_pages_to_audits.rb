class AddPagesToAudits < ActiveRecord::Migration[8.0]
  def change
    add_column :audits, :home_page_html, :text
    add_column :audits, :accessibility_page_html, :text
  end
end
