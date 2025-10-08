class Check < ApplicationRecord
  has_many :check_transitions, autosave: false, dependent: :destroy

  include Statesman::Adapters::ActiveRecordQueries[
            transition_class: CheckTransition,
            initial_state: :pending
          ]

  def state_machine
    Statesman::Machine.retry_conflicts do
      @state_machine ||= CheckStateMachine.new(
        self,
        transition_class: CheckTransition,
        association_name: :check_transitions,
        initial_transition: true
      )
    end
  end

  delegate :current_state,
           :transition_to,
           :transition_to!,
           :in_state?,
           :can_transition_to?,
           :last_transition,
           to: :state_machine

  # defines single word predicates for each state
  CheckStateMachine.states.each do |state|
    define_method "#{state}?" do
      in_state?(state)
    end
  end

  SLOW = false

  TYPES = [
    :reachable,
    :language_indication,
    :accessibility_mention,
    :find_accessibility_page,
    :analyze_accessibility_page,
    :accessibility_page_heading,
    :run_axe_on_homepage,
  ].freeze

  # used to signal a check's `run` method has failed
  class RuntimeError < StandardError; end

  PRIORITY = 100 # Override in subclasses if necessary, lower numbers run first
  REQUIREMENTS = [:reachable]

  belongs_to :audit
  has_one :site, through: :audit

  delegate :parsed_url, to: :audit
  delegate :human_type, to: :class

  after_initialize :set_priority

  scope :prioritized, -> { order(:priority) }
  scope :remaining, -> { in_state(:pending, :blocked) }
  scope :errored, -> { in_state(:failed) }

  broadcasts_refreshes_to ->(check) { "sites" }

  class << self
    def human_type = human(:type)
    def table_header = human(:table_header, default: human_type)

    def types
      @types ||= TYPES.index_with { |type| "Checks::#{type.to_s.classify}".constantize }.sort_by { |_name, klass| klass.priority }.to_h
    end
    def names = types.keys
    def classes = types.values
    def priority = self::PRIORITY
  end

  def human_status = Check.human("status.#{state_machine.current_state}")
  def to_partial_path = model_name.i18n_key.to_s
  def root_page = @root_page ||= Page.new(url: audit.url)
  def crawler = Crawler.new(audit.url)
  def requirements = self.class::REQUIREMENTS # Returns subclass constant value, defaults to parent class
  def tooltip? = true
  def slow? = self.class::SLOW

  def run!
    self.data = analyze!

    save!
  rescue StandardError => exception
    raise Check::RuntimeError
  end

  def all_requirements_met?
    requirements.all? { |requirement| audit.check_completed?(requirement) }
  end

  def depends_on?(requirement)
    requirements.include?(requirement)
  end

  def to_requirement
    type
      .demodulize
      .underscore
      .to_sym
  end

  def error
    return unless errored?

    error_type, message, backtrace = last_transition.metadata.slice("json_class", "m", "b").values
    app_path = Rails.root.to_s
    backtrace = backtrace.collect { it.sub(app_path, "") }
    { error_type:, message:, backtrace: }
  end

  private

  def analyze! = raise NotImplementedError.new("#{model_name} needs to implement the `#{__method__}` private method")

  def set_priority = self.priority = self.class.priority
end
