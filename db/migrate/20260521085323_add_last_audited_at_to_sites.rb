class AddLastAuditedAtToSites < ActiveRecord::Migration[8.1]
  def change
    add_column :sites, :last_audited_at, :datetime
  end
end
