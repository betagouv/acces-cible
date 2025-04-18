class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  delegate :l, to: :I18n
  delegate :human, :human_count, :to_percent, :helpers, to: :class

  class << self
    delegate :helpers, to: ApplicationController

    alias human human_attribute_name
    def human_count(attr = :count, count: nil) = human(attr, count: count || send(attr))
    def to_percent(number, **options) = helpers.number_to_percentage(number, options.merge(precision: 2, strip_insignificant_zeros: true))
  end

  def to_title = respond_to?(:name) ? name : to_s
end
