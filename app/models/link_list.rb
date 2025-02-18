class LinkList
  include Enumerable

  class EmptyListError < StandardError; end

  delegate :size, :length, :empty?, :inspect, :each, :sort_by, to: :list

  def initialize(*links)
    @list = links.flatten.compact.collect { |link| Link.from(link) }
  end

  def <<(link)
    link = Link.from(link)
    list.append(link) unless list.include?(link)
    self
  end

  def prepend_unique(link)
    link = Link.from(link)
    list.prepend(link) unless list.include?(link)
    self
  end

  def add(*links)
    links.uniq.each { |link| self << Link.from(link) }
    self
  end

  def sort_by
    return self if size < 2

    list = list.sort { |a, b|  yield(a, b) }
    self
  end

  def include?(link) = to_set.include? Link.from(link).href
  def shift = empty? ? raise(EmptyListError.new) : list.shift
  def ==(other) = to_set == other.to_set
  def to_set = list.collect(&:href).to_set

  private

  attr_accessor :list
end
