class BackfillAuditsWithUser < ActiveRecord::Migration[8.1]
  def up
    Site.find_in_batches do |sites|
      sites.each { |site| site.audits.update_all(user_id: site.team.users.pick(:id)) }
    end
  end
end
