class ChangeDefaultCommittedBalanceInUsers < ActiveRecord::Migration[6.0]
  def change
    change_column :users, :committed_balance, :float, default: 0
  end
end
