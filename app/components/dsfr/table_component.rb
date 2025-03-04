# frozen_string_literal: true

module Dsfr
  class TableComponent < ApplicationComponent
    renders_one :head
    renders_one :body

    SIZES = [:sm, :md, :lg].freeze

    def initialize(caption:, size: :md, scroll: true, border: false, html_attributes: {})
      @caption = caption
      @size = size.to_sym
      @scroll = scroll
      @border = border
      @html_attributes = html_attributes

      raise ArgumentError, "size must be one of: #{SIZES.join(', ')}" unless SIZES.include?(@size)
    end

    private

    attr_reader :caption, :size, :border, :scroll, :html_attributes

    def table_classes
      classes = ["fr-table"]
      classes << "fr-table--#{size}" if [:sm, :lg].include?(size)
      classes << "fr-table--border" if border
      classes << "fr-table--no-scroll" unless scroll
      classes.join(" ")
    end
  end
end
