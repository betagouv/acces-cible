class RemoveCurrentFromAudits < ActiveRecord::Migration[8.1]
  def up
    remove_column :audits, :current, :boolean
  end

  def down
    add_column :audits, :current, :boolean, default: false, null: false

    Site.find_in_batches do |sites|
      sites.each do |site|
        current_audit = site.audits.where(completed_at: site.last_audited_at).first
        next if current_audit.blank?
        current_audit.update_column(:current, true)
      end
    end
  end
end
