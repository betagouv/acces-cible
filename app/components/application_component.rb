# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  include ComponentStoreAccessor

  delegate :human, to: :class

  class << self
    def human(key, **options)
      component = name.underscore.gsub("/", ".").delete_suffix("_component")
      defaults = [
        :"viewcomponent.#{component}.#{key}",
        :"viewcomponent.#{component}/#{key}",
        :"viewcomponent.#{key}",
        :"attributes.#{key}",
        options[:default]
      ].compact
      options[:count] ||= 1
      I18n.t defaults.shift, **options, default: defaults
    end
  end
end
