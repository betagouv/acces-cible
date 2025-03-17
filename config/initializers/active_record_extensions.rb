ActiveSupport.on_load(:active_record) do
  module QueryExtensions
    def query_object_class = "#{model.name}Query".safe_constantize

    def filter_by(params)
      if query_object_class
        query_object_class.new(self).filter_by(params)
      else
        raise NameError, "Missing #{model.name}Query class for #{model.name}.filter_by"
      end
    end

    def sort_by(params, default_scope: nil)
      key, direction = params[:sort]&.to_unsafe_h&.first
      directions = [:asc, :desc]
      direction = direction.to_s.downcase.to_sym.presence_in(directions) || directions.first
      if query_object_class
        query_object_class.new(self).sort_by(key&.to_sym, direction:, default_scope:) || self
      elsif key = key.presence_in(model.column_names)
        order(key => direction)
      elsif default_scope
        public_send(default_scope)
      else
        order("created_at" => direction)
      end
    end
  end

  ActiveRecord::Relation.include(QueryExtensions)
end
