class AddCountersToSitesAndTags < ActiveRecord::Migration[8.0]
  def change
    add_column :sites, :tags_count, :integer, null: false, default: 0
    add_column :tags, :sites_count, :integer, null: false, default: 0

    up_only do
      say_with_time "Updating sites.tags_count" do
        Site.bulk_reset_counter(:tags)
      end
      say_with_time "Updating tags.sites_count" do
        Tag.bulk_reset_counter(:sites)
      end
    end
  end
end
