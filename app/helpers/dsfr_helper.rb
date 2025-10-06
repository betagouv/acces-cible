module DsfrHelper
  def dsfr_table(caption:, pagy: @pagy, size: :md, scroll: true, border: false, **html_attributes, &block)
    render Dsfr::TableComponent.new(caption:, pagy:, size:, scroll:, border:, html_attributes:), &block
  end

  def dsfr_sidemenu(title:, button: nil, sticky: false, full_height: false, right: false, &block)
    component = Dsfr::SidemenuComponent.new(title:, button:, sticky:, full_height:, right:)
    yield(component) if block_given?
    render component
  end

  def dsfr_pagination
    render Dsfr::PaginationComponent.new(pagy: @pagy)
  end

  def dsfr_tooltip(text, title:, type: :button)
    render Dsfr::TooltipComponent.new(text, title:, type:)
  end

  def dsfr_row_check(record)
    input_id = "row_check_#{record.id}"
    text = t("shared.select_name", name: record.to_s)
    content_tag :th, class: "fr-cell--fixed fr-enlarge-input", scope: "row" do
      content_tag :div, class: "fr-checkbox-group fr-checkbox-group--sm", title: text do
        safe_join([
          check_box_tag("id[]", record.id, false, id: input_id, form: "table_form", data: { fr_row_select: "true", action: "table#toggle", table_target: "checkbox" }),
          label_tag(input_id, text, class: "fr-label")
        ])
      end
    end
  end

  def dsfr_row_check_all
    input_id = "row_check_all"
    text = t("shared.select_name", name: t("shared.all_lines"))
    content_tag :th, class: "fr-cell--fixed fr-enlarge-input", role: "columnheader" do
      content_tag :div, class: "fr-checkbox-group fr-checkbox-group--sm", title: text do
        safe_join([
          check_box_tag(nil, nil, false, id: input_id, data: { action: "table#toggleAll", table_target: "toggleAll" }),
          label_tag(input_id, text, class: "fr-label")
        ])
      end
    end
  end

  def dsfr_badge(status:, html_attributes: {}, &block)
    html_attributes[:class] = class_names("fr-badge", "fr-badge--#{status}", html_attributes[:class])
    tag.p(**html_attributes, &block)
  end
end
