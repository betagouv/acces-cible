module ComponentStoreAccessor
  extend ActiveSupport::Concern

  class_methods do
    def store_accessor(store_attribute, *keys)
      attr_accessor store_attribute unless method_defined?(store_attribute)
      _store_accessors_module.module_eval do
        keys.flatten.each do |key|
          define_method("#{key}=") do |value|
            store = instance_variable_get("@#{store_attribute}") || {}
            store[key.to_sym] = value
            instance_variable_set("@#{store_attribute}", store)
          end

          define_method(key) do
            store = instance_variable_get("@#{store_attribute}") || {}
            store[key.to_sym]
          end
        end
      end
    end

    private

    def _store_accessors_module
      @_store_accessors_module ||= begin
        mod = Module.new
        include mod
        mod
      end
    end
  end
end
