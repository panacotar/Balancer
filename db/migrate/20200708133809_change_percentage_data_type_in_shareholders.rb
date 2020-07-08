class ChangePercentageDataTypeInShareholders < ActiveRecord::Migration[6.0]
  def change
    change_column :shareholders, :percentage, :float
  end
end
