require 'test_helper'

class CampaignTest < ActiveSupport::TestCase
  test 'funding progress and remaining pledges preserve decimals' do
    campaign = create_campaign(investment_goal: 100)
    Shareholder.create!(campaign: campaign, user: create_user, amount: '25.50', percentage: '2.55', status: 'Active')
    assert_equal 25, campaign.percent
    assert_equal BigDecimal('74.50'), campaign.remaining_pledge
  end
end
