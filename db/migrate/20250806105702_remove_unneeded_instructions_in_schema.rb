class RemoveUnneededInstructionsInSchema < ActiveRecord::Migration[8.0]
  def change
    [:cable, :cache, :queue].each do |kind|
      schema_name = "acces_cible_development_#{kind}"
      drop_schema schema_name if schema_exists?(schema_name)
    end

    remove_index :sites, :audit_id, if_exists: true
  end
end
