class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  delegate :l, to: :I18n
  delegate :human, :to_percent, :helpers, to: :class
  delegate :report, to: ErrorHelper

  class << self
    delegate :helpers, to: ApplicationController

    alias human human_attribute_name
    def human_count(attr = :count, count: nil) = human(attr, count: count || send(attr))
    def to_percent(number, **options) = helpers.number_to_percentage(number, options.with_defaults(precision: 0, strip_insignificant_zeros: true))

    def bulk_reset_counter(association, counter: nil)
      reflection = reflect_on_association(association)
      raise ArgumentError, "Association #{association} not found in #{self.name} model" unless reflection

      counter ||= "#{reflection.name}_count"

      unless [:has_many, :has_and_belongs_to_many].include?(reflection.macro)
        raise ArgumentError, "Association #{association} must be has_many or has_and_belongs_to_many"
      end

      reflection = reflection.through_reflection if reflection.through_reflection?
      case
      when reflection.macro == :has_many
        table = reflection.klass.table_name
        foreign_key = reflection.foreign_key
      when reflection.macro == :has_and_belongs_to_many
        table = reflection.join_table
        foreign_key = reflection.association_foreign_key
      end

      update_all(counter: "(SELECT count(*) FROM #{table} WHERE #{table}.#{foreign_key} = #{table_name}.#{primary_key})")
    end
  end

  def to_title = respond_to?(:name) ? name : to_s
  def human_count(attr, count: nil) = human(attr, count: count || send(attr))
end
