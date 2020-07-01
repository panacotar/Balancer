class ChangeAmountAndPercentageInShareholders < ActiveRecord::Migration[6.0]
  def change
    change_column :shareholders, :amount, :float, default: 0.0
    change_column :shareholders, :percentage, :integer
  end
end
