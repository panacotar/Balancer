class AddPriceToCampaign < ActiveRecord::Migration[6.0]
  def change
    add_monetize :campaigns, :price, currency: { present: false }
  end
end
