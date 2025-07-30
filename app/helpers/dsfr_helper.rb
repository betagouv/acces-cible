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
    <<-HTML.html_safe
    <th class="fr-cell--fixed fr-enlarge-input" scope="row">
      <div class="fr-checkbox-group fr-checkbox-group--sm" title="#{text}">
        <input type="checkbox" name="id[]" value="#{record.id}" id="#{input_id}" form="table_form" data-fr-row-select="true" data-action="table#toggle" data-table-target="checkbox">
        <label for="#{input_id}" class="fr-label">#{text}</label>
      </div>
    </th>
    HTML
  end

  def dsfr_row_check_all
    input_id = "row_check_all"
    text = t("shared.select_name", name: t("shared.all_lines"))
    <<-HTML.html_safe
    <th class="fr-cell--fixed fr-enlarge-input" role="columnheader">
      <div class="fr-checkbox-group fr-checkbox-group--sm" title="#{text}">
        <input type="checkbox" id="#{input_id}" data-action="table#toggleAll" data-table-target="toggleAll">
        <label for="#{input_id}" class="fr-label">#{text}</label>
      </div>
    </th>
    HTML
  end

  def dsfr_badge(status:, html_attributes: {}, &block)
    html_attributes[:class] = class_names("fr-badge", "fr-badge--#{status}", html_attributes[:class])
    tag.p(**html_attributes, &block)
  end
end
