class AddAccessibilityPageUrlToAudits < ActiveRecord::Migration[8.0]
  def change
    add_column :audits, :accessibility_page_url, :string
  end
end
