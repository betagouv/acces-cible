if Rails.env.local? && Dsfr::FormBuilder.instance_methods.include?(:dsfr_file_field)
  raise "The dsfr-form_builder gem now implements dsfr_file_input. You can remove this initializer."
end

Dsfr::FormBuilder.class_eval do
  def dsfr_file_field(attribute, opts = {})
    group_classes = [
      "fr-upload-group",
      @object.errors[attribute].any? ? "fr-upload-group--error" : nil,
      opts[:class],
    ].compact.join(" ")

    input_opts = {
      class: "fr-upload",
    }

    if @object.errors[attribute].any?
      error_id = "#{attribute}-desc-error"
      input_opts[:aria] = { describedby: error_id }
    end

    @template.content_tag(:div, class: group_classes, data: opts[:data]) do
      @template.safe_join(
        [
          dsfr_label_with_hint(attribute, opts.except(:class)),
          file_field(attribute, input_opts.merge(opts.except(:class, :data, :hint, :label))),
          dsfr_error_message(attribute),
        ].compact
      )
    end
  end
end
