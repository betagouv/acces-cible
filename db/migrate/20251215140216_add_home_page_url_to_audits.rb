class AddHomePageUrlToAudits < ActiveRecord::Migration[8.1]
  def change
    add_column :audits, :home_page_url, :string
  end
end
