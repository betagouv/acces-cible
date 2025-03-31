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

  def dom_id(prefix: nil, suffix: nil)
    [prefix, self.class.name.demodulize, object_id, suffix].compact.join("_").underscore
  end
end
