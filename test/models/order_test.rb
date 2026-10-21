require 'test_helper'

class OrderTest < ActiveSupport::TestCase
  test 'pledges parse exact euros and cents without truncation' do
    assert_equal 2550, Order.parse_pledge('25.50').cents
    assert_equal 1, Order.parse_pledge('0.01').cents
    assert_equal 10000, Order.parse_pledge('100').cents
    %w[0 -1 1.001 1e3 NaN Infinity 1,50 21474836.48].each do |value|
      assert_raises(ArgumentError, value) { Order.parse_pledge(value) }
    end
    assert_raises(ArgumentError) { Order.parse_pledge(nil) }
  end

  test 'money survives persistence and explicit rounding uses half even' do
    order = create_order(amount: Money.from_amount(BigDecimal('25.50'), 'EUR'))
    assert_equal 2550, order.reload.amount_cents
    assert_equal 'EUR', order.amount.currency.iso_code
    assert_equal 100, Money.from_amount(BigDecimal('1.005'), 'EUR').cents
    assert_equal 102, Money.from_amount(BigDecimal('1.015'), 'EUR').cents
  end
end
