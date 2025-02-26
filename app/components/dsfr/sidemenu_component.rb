# frozen_string_literal: true

module Dsfr
  class SidemenuComponent < ApplicationComponent
    DEFAULT_BUTTON_TEXT = "Dans cette rubrique".freeze

    renders_many :items, "Dsfr::SidemenuItemComponent"

    attr_reader :title, :button, :sticky, :full_height, :right

    def initialize(title:, button: DEFAULT_BUTTON_TEXT, sticky: false, full_height: false, right: false)
      @title = title
      @button = button
      @full_height = full_height
      @sticky = full_height || sticky
      @right = right
    end

    def css_classes
      token_list(
        "fr-sidemenu",
        "fr-sidemenu--sticky" => sticky,
        "fr-sidemenu--sticky-full-height" => full_height,
        "fr-sidemenu--right" => right
      )
    end

    def render? = items.any?
  end
end
