# frozen_string_literal: true

module Dsfr
  # This class is used by the Sidemenu component via renders_many
  class SidemenuItemComponent < ApplicationComponent
    attr_reader :href, :text, :active

    def initialize(href:, text:, active: nil)
      @href = href
      @text = text
      @active = active
    end

    def active
      @active.nil? ? helpers.current_page?(href) : @active
    end

    def call
      content_tag :li, class: token_list("fr-sidemenu__item", "fr-sidemenu__item--active" => active) do
        content_tag :a, href:, class: "fr-sidemenu__link", "aria-current": active ? :page : nil do text end
      end
    end
  end
end
