class ChangeForeignKeysToSingular < ActiveRecord::Migration[6.0]
  def change
    rename_column :projects, :users_id, :user_id
    rename_column :shareholders, :users_id, :user_id
    rename_column :shareholders, :campaigns_id, :campaign_id
    rename_column :transactions, :users_id, :user_id
  end
end
