class AddRunAxeOnHomepageToAuditBatches < ActiveRecord::Migration[8.1]
  def change
    add_column :audit_batches, :run_axe_on_homepage, :boolean, null: false, default: true
  end
end
