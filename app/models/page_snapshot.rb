class PageSnapshot < ApplicationRecord
  belongs_to :audit

  enum :kind, { home: "home", accessibility: "accessibility" }

  def responded?
    status.present?
  end

  def auditable?
    HTTP::Response::Status.new(status).success? && html? && Page.html_content_type?(content_type)
  end
end
