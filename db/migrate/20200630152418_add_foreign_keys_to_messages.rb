class AddForeignKeysToMessages < ActiveRecord::Migration[6.0]
  def change
    add_column :messages, :user_sender_id, :integer
    add_column :messages, :user_receiver_id, :integer
  end
end
