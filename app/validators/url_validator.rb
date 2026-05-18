class UrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?
    return if Link.safe_external_url(value)

    record.errors.add(attribute, :invalid)
  end
end
