class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  delegate :l, to: :I18n
  delegate :human, :human_count, :helpers, to: :class

  class << self
    delegate :helpers, to: ApplicationController

    alias human human_attribute_name
    def human_count(attr = :count, count: nil) = human(attr, count: count || send(attr))
  end

  def to_title = respond_to?(:name) ? name : to_s
end
