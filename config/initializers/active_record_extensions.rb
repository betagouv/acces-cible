ActiveSupport.on_load(:active_record) do
  module CsvExportExtensions
    def export_object_class
      "#{model.name}CsvExport".constantize
    end

    def to_csv
      export_object_class.new(self).to_csv
    end

    def to_csv_filename
      export_object_class.new(self).filename
    end
  end
  ActiveRecord::Relation.include(CsvExportExtensions)
end
