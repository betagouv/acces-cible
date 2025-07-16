# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  include ComponentStoreAccessor

  delegate :human, to: :class

  class << self
    def human(key, options = {})
      options[:count] ||= 1
      component = name.underscore.gsub("/", ".").delete_suffix("_component")
      I18n.translate("viewcomponent.#{component}.#{key}", **options)
    end
  end

  def dom_id(object = nil, prefix: nil, suffix: nil)
    object ||= self # Default to the current component
    klass, id = if object.is_a?(ApplicationRecord)
      [object.model_name.param_key, object.to_param]
    else
      [object.class.name.gsub("::", "_"), object.object_id]
    end
    [prefix, klass, id, suffix].compact.join("_").underscore.gsub(/[^a-z0-9_]/i, "")
  end
end
