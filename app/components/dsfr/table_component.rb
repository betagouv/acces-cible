# frozen_string_literal: true

module Dsfr
  class TableComponent < ApplicationComponent
    renders_one :head
    renders_one :body
    renders_one :search, DsfrComponent::SearchComponent
    renders_many :footer_actions

    SIZES = [:sm, :md, :lg].freeze

    def initialize(caption:, pagy:, html_attributes: {}, **options)
      @caption = caption
      @pagy = pagy
      @size = options.delete(:size)&.to_sym || :md
      @scroll = options.delete(:scroll) { true }
      @border = options.delete(:border)
      @caption_side = options.delete(:caption_side)
      @html_attributes = html_attributes

      raise ArgumentError, "size must be one of: #{SIZES.join(', ')}" unless SIZES.include?(@size)
    end

    private

    attr_reader :caption, :caption_side, :pagy, :size, :border, :scroll, :html_attributes

    def wrapper_attributes
      html_attributes.merge(class: table_classes)
    end

    def table_classes
      class_names(
        html_attributes.delete(:class),
        "fr-table",
        "fr-table--#{size}" => [:sm, :lg].include?(size),
        "fr-table--border" => border,
        "fr-table--no-scroll" => !scroll,
        "fr-table--no-caption" => caption_side == :hidden,
        "fr-table--caption-bottom" => caption_side == :bottom,
      )
    end

    def pagination? = pagination.render?
    def pagination = PaginationComponent.new(pagy:)
    def total_lines = human(:lines, count: pagy.count)
  end
end
