class AddForeignKeytoCampaigns < ActiveRecord::Migration[6.0]
  def change
    add_reference :campaigns, :project, foreign_key: true
  end
end
