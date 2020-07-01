class ChangeStatusInShareholders < ActiveRecord::Migration[6.0]
  def change
     change_column :shareholders, :status, :string
  end
end
