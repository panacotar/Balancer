class AddChangeStatusDatatypeInTransactions < ActiveRecord::Migration[6.0]
  def change
    remove_column :transactions, :status, :string
    add_column :transactions, :status, :boolean, default: true
  end

end
