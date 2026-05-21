class BackfillLastAuditedAt < ActiveRecord::Migration[8.1]
  def up
    Site.find_in_batches do |sites|
      sites.each do |site|
        last_audited_at = site.audits.where.not(completed_at: nil).first&.completed_at
        next if last_audited_at.blank?
        site.update_column(:last_audited_at, last_audited_at)
      end
    end
  end
end
