class AddAmountAndPercentageToCampaigns < ActiveRecord::Migration[6.0]
  def change
    add_column :campaigns, :amount, :float
    add_column :campaigns, :percentage, :integer
  end
end
