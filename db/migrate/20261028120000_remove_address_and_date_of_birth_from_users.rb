class RemoveAddressAndDateOfBirthFromUsers < ActiveRecord::Migration[8.1]
  def change
    remove_column :users, :address, :string
    remove_column :users, :date_of_birth, :datetime
  end
end
