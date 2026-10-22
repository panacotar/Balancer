require 'test_helper'

class CampaignTest < ActiveSupport::TestCase
  test 'funding progress and remaining pledges preserve decimals' do
    campaign = create_campaign(investment_goal: 100)
    Shareholder.create!(campaign: campaign, user: create_user, amount: '25.50', percentage: '2.55', status: 'Active')
    assert_equal 25, campaign.percent
    assert_equal BigDecimal('74.50'), campaign.remaining_pledge
  end

  test 'pending orders reserve pledge room without counting as funded' do
    campaign = create_campaign(investment_goal: 100)
    create_order(campaign: campaign, amount: BigDecimal('25.50'))
    create_order(campaign: campaign, amount: BigDecimal('10'), state: 'failed')
    assert_equal BigDecimal('74.50'), campaign.available_pledge
    assert_equal BigDecimal('100'), campaign.remaining_pledge
    assert_equal 0, campaign.percent
  end
end
