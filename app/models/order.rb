class Order < ApplicationRecord
  belongs_to :user
  belongs_to :campaign
  has_one :shareholder, dependent: :destroy
  monetize :amount_cents, numericality: { greater_than: 0 }
  validates :state, inclusion: { in: %w[pending paid failed] }
  validates :campaign_sku, presence: true

  def self.parse_pledge(value)
    raise ArgumentError unless value.is_a?(String) && value.match?(/\A\d+(?:\.\d{1,2})?\z/)

    amount = BigDecimal(value)
    raise ArgumentError unless amount.positive? && amount <= BigDecimal('21474836.47')

    Money.from_amount(amount, 'EUR')
  end
end
