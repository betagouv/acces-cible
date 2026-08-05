namespace :one_off do
  desc "Backfill page snapshots from audits home/accessibility page columns"

  task backfill_page_snapshots: :environment do
    Audit.where.missing(:page_snapshots).in_batches do |batch|
      OneOff::BackfillPageSnapshotsJob.perform_later(batch.ids)
    end
  end

  desc "Backfill checks conform/found columns from their data"

  task backfill_checks_conform_and_found: :environment do
    Audit.in_batches do |batch|
      OneOff::BackfillChecksConformAndFoundJob.perform_later(batch.ids)
    end
  end

  desc "Backfill audits legal_obligation_score/declaration_quality_score from their checks"

  task backfill_audits_scores: :environment do
    Audit.in_batches do |batch|
      OneOff::BackfillAuditsScoresJob.perform_later(batch.ids)
    end
  end
end
