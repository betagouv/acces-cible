class AddLegalObligationScoreAndDeclarationQualityScoreToAudits < ActiveRecord::Migration[8.1]
  def change
    add_column :audits, :legal_obligation_score, :float
    add_column :audits, :declaration_quality_score, :float
  end
end
