class AddColumnsToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :first_name, :string
    add_column :users, :last_name, :string
    add_column :users, :address, :string
    add_column :users, :date_of_birth, :datetime
    add_column :users, :gender, :string
    add_column :users, :phone_number, :string
    add_column :users, :status, :boolean
    add_column :users, :balance, :integer
    add_column :users, :committed_balance, :integer
    add_column :users, :admin, :boolean
  end
end
