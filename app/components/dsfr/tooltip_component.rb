# frozen_string_literal: true

module Dsfr
  class TooltipComponent < ApplicationComponent
    def initialize(text, title:, type: :button)
      @text = text
      @title = title
      @type = type&.to_sym || :button
    end

    def call
      [(button? ? button : link), tooltip].join(" ").html_safe
    end

    private

    attr_reader :text, :title

    def button? = @type == :button

    def link
      content_tag :a, text, tabindex: 0, class: "fr-link", id: element_id, "aria-describedby": tooltip_id, "data-turbo": false
    end

    def button
      button_tag text, type: :button, class: "fr-btn fr-btn--tooltip", id: element_id, "aria-describedby": tooltip_id
    end

    def tooltip
      content_tag :span, title, class: "fr-tooltip fr-placement", id: tooltip_id, role: :tooltip, "aria-hidden": "true"
    end

    def tooltip_id
      "tooltip-#{object_id}"
    end

    def element_id
      "#{tooltip_id}-opener"
    end
  end
end
