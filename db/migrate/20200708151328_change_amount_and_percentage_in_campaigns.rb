class ChangeAmountAndPercentageInCampaigns < ActiveRecord::Migration[6.0]
  def change
    change_column :campaigns, :amount, :integer
    rename_column :campaigns, :amount, :investment_goal
    rename_column :campaigns, :percentage, :equity
  end
end
