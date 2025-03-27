# frozen_string_literal: true

module Dsfr
  class TableComponent < ApplicationComponent
    renders_one :head
    renders_one :body
    renders_one :pagination, -> { PaginationComponent.new(pagy: @pagy) }
    renders_many :footer_actions

    SIZES = [:sm, :md, :lg].freeze

    def initialize(caption:, pagy:, size: :md, scroll: true, border: false, html_attributes: {})
      @caption = caption
      @pagy = pagy
      @size = size.to_sym
      @scroll = scroll
      @border = border
      @html_attributes = html_attributes

      raise ArgumentError, "size must be one of: #{SIZES.join(', ')}" unless SIZES.include?(@size)
    end

    private

    attr_reader :caption, :pagy, :size, :border, :scroll, :html_attributes

    def wrapper_attributes
      html_attributes.merge(class: table_classes)
    end

    def table_classes
      class_names(
        html_attributes.delete(:class),
        "fr-table",
        "fr-table--#{size}" => [:sm, :lg].include?(size),
        "fr-table--border" => border,
        "fr-table--no-scroll" => !scroll
      )
    end

    def total_lines = human(:lines, count: pagy.count)
  end
end
