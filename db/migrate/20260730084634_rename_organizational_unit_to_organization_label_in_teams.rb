class RenameOrganizationalUnitToOrganizationLabelInTeams < ActiveRecord::Migration[8.1]
  def change
    rename_column :teams, :organizational_unit, :organization_label
  end
end
