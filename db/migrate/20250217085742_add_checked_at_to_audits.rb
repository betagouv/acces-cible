class AddCheckedAtToAudits < ActiveRecord::Migration[8.0]
  def change
    add_column :audits, :checked_at, :datetime
    Audit.past.update_all(checked_at: Time.current) unless reverting?
  end
end
