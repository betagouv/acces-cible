class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank? || value.match?(URI::MailTo::EMAIL_REGEXP)

    record.errors.add(attribute, :invalid)
  end
end
