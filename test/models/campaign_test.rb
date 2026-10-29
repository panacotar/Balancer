require 'test_helper'

class CampaignTest < ActiveSupport::TestCase
  setup do
    owner = create_user(email: 'campaign-owner@example.com')
    @campaign = create_campaign_for(owner, name: 'Goal Round')
  end

  test 'investment goal must be a positive whole number' do
    @campaign.investment_goal = '10.5'
    assert_not @campaign.valid?
    assert_includes @campaign.errors[:investment_goal], 'must be an integer'

    @campaign.investment_goal = 'abc'
    assert_not @campaign.valid?

    @campaign.investment_goal = 0
    assert_not @campaign.valid?

    @campaign.investment_goal = 1000
    assert @campaign.valid?
  end

  test 'equity must be a whole number from 1 to 100' do
    @campaign.equity = 0
    assert_not @campaign.valid?

    @campaign.equity = 101
    assert_not @campaign.valid?
    assert_includes @campaign.errors[:equity], 'must be less than or equal to 100'

    @campaign.equity = '10.5'
    assert_not @campaign.valid?

    @campaign.equity = 100
    assert @campaign.valid?
  end
end
