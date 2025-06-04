class SiteTag < ApplicationRecord
  belongs_to :site
  belongs_to :tag, touch: true
end
