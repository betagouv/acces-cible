# frozen_string_literal: true

module Dsfr
  class TableComponent < ApplicationComponent
    renders_one :head
    renders_one :body
    renders_one :search, DsfrComponent::SearchComponent
    renders_many :header_actions
    renders_many :footer_actions

    SIZES = [:sm, :md, :lg].freeze

    def initialize(caption:, pagy: nil, html_attributes: {}, **options)
      @caption = caption
      @pagy = pagy
      options[:scroll] = options.fetch(:scroll, true)
      options[:size] = options[:size]&.to_sym || :md
      @options = options
      @html_attributes = html_attributes

      raise ArgumentError, "size must be one of: #{SIZES.join(', ')}" unless SIZES.include?(size)
    end

    private

    attr_reader :caption, :pagy, :html_attributes
    store_accessor :options, :size, :border, :scroll, :caption_side

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

    def paginated? = pagy.present?
    def multipage? = pagination&.render?
    def pagination = (PaginationComponent.new(pagy:) if pagy)
    def total_lines = human(:lines, count: pagy.count)
    def header_actions? = header_actions.any?
    def header? = search? || header_actions?
  end
end
