class SiteTag < ApplicationRecord
  belongs_to :site, counter_cache: :tags_count
  belongs_to :tag, counter_cache: :sites_count, touch: true
end
