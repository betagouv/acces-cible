module Dsfr
  class PaginationComponent < ApplicationComponent
    LINK_CLASS = "fr-pagination__link".freeze

    def initialize(pagy:)
      @pagy = pagy
    end

    def render? = pagy.last > 1
    def items = [first_page, previous_page, *series, next_page, last_page]

    private

    attr_reader :pagy

    def first_page
      page_link(
        human(:first),
        page: 1,
        modifier: :first,
        disabled: pagy.page == 1
      )
    end

    def previous_page
      page_link(
        human(:prev),
        page: pagy.prev,
        modifier: :prev,
        disabled: pagy.page == 1
      )
    end

    def next_page
      page_link(
        human(:next),
        page: pagy.next,
        modifier: :next,
        disabled: !pagy.next
      )
    end

    def last_page
      page_link(
        human(:last),
        page: pagy.last,
        modifier: :last,
        disabled: pagy.page == pagy.last
      )
    end

    def series
      pagy.series.map do |page|
        case page
        when :gap
          tag.span "…", class: LINK_CLASS
        when String # current page
          page_link(page, title: human(:page, page:), aria: { current: :page })
        else # regular page link
          page_link(page, page:, title: human(:page, page:))
        end
      end
    end

    def page_link(text, page: nil, modifier: nil, disabled: false, **options)
      options[:class] = class_names(LINK_CLASS, "#{LINK_CLASS}--#{modifier}" => modifier)
      if disabled
        tag.a text, class: options[:class], role: :link, aria: { disabled: true }
      else
        link_to text, helpers.pagy_url_for(pagy, page), **options
      end
    end
  end
end
