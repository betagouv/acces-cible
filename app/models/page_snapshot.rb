class PageSnapshot < ApplicationRecord
  belongs_to :audit

  enum :kind, { home: "home", accessibility: "accessibility" }
end
