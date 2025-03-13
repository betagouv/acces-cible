class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  delegate :l, to: :I18n
  delegate :human, :human_count, to: :class
  delegate :helpers, to: ApplicationController

  class << self
    alias human human_attribute_name
    def human_count(count, attr = nil) = human(attr || :count, count:)
  end

  def to_title = respond_to?(:name) ? name : to_s
end
