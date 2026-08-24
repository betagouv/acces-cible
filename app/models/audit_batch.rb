class AuditBatch < ApplicationRecord
  belongs_to :user
  has_many :audits

  enum :kind, { manual: "manual", csv_import: "csv_import" }
  enum :status, { draft: "draft", launched: "launched" }

  validates :kind, presence: true

  def complete?
    audits.exists? && audits.where(completed_at: nil).none?
  end

  def progress
    { total: audits.count, completed: audits.completed.count }
  end
end
