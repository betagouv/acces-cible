class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  delegate :l, to: :I18n
  delegate :human, :human_count, to: :class

  class << self
    alias human human_attribute_name
    def human_count(count, attr = nil) = human(attr || :count, count:)
  end
end
