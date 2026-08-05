namespace :one_off do
  desc "Backfill page snapshots from audits home/accessibility page columns"

  task backfill_page_snapshots: :environment do
    Audit.where.missing(:page_snapshots).in_batches do |batch|
      OneOff::BackfillPageSnapshotsJob.perform_later(batch.ids)
    end
  end
end
