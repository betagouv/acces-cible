module Privileged
  extend ActiveSupport::Concern

  PRIVILEGED_SIRETS = %w[11000029600274 11000029600027].freeze

  def privileged?
    PRIVILEGED_SIRETS.include?(siret)
  end
end
