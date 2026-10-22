require 'test_helper'

class CampaignPolicyTest < ActiveSupport::TestCase
  test 'both creation and editing require project ownership' do
    campaign = create_campaign
    assert CampaignPolicy.new(campaign.project.user, campaign).create?
    assert CampaignPolicy.new(campaign.project.user, campaign).update?
    assert_not CampaignPolicy.new(create_user, campaign).update?
    assert_not CampaignPolicy.new(nil, campaign).create?
  end
end
