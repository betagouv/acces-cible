# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  delegate :human, to: :class

  class << self
    def human(key, options = {})
      options[:count] ||= 1
      component = name.underscore.gsub("/", ".").delete_suffix("_component")
      I18n.translate("viewcomponent.#{component}.#{key}", **options)
    end
  end
end
