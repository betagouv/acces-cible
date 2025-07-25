class ApplicationExport
  delegate :l, to: :I18n
  delegate :model, :table_name, to: :relation
  delegate :human, to: :model

  attr_reader :relation

  def initialize(relation)
    @relation = relation
  end

  def extension
    self.class::EXTENSION
  rescue NameError
    raise NotImplementedError, "#{self.class} must define EXTENSION constant"
  end

  def attributes
    raise NotImplementedError, "#{self.class} must implement #attributes method"
  end

  def filename = "#{table_name}_#{l Time.zone.now, format: :file}.#{extension}"
  def records = relation.find_each
  def headers = attributes.keys

  def serialize(record)
    attributes.values.map do |methods|
      # Turns [:a, :b, :c] into record.a&.b&.c
      Array.wrap(methods).reduce(record) { |obj, method| obj&.public_send(method) }
    end
  end
end
