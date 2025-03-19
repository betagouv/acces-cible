class ApplicationExport
  delegate :l, to: :I18n
  delegate :model, :table_name, to: :relation
  delegate :human, to: :model

  attr_reader :relation

  def initialize(relation)
    @relation = relation
  end

  def extension = self.class::EXTENSION
  def filename = "#{table_name}_#{l Time.zone.now, format: :file}.#{extension}"
  def records = relation.find_each
end
