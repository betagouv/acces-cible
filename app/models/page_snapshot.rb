class PageSnapshot < ApplicationRecord
  belongs_to :audit

  enum :kind, { home: "home", accessibility: "accessibility" }

  def responded?
    status.present?
  end

  def auditable?
    HTTP::Response::Status.new(status).success?
  end
end
