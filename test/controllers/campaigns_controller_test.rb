require 'test_helper'

class CampaignsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'another user cannot edit a campaign' do
    owner = create_user(email: 'edit-owner@example.com', phone: '5550005555')
    other = create_user(email: 'edit-other@example.com', phone: '5550006666')
    campaign = create_campaign_for(owner, name: 'Edit Round')
    sign_in other

    patch project_campaign_path(campaign.project, campaign), params: { campaign: { name: 'Hacked' } }
    assert_includes [403, 500], response.status, response.body
    assert_equal 'Edit Round', campaign.reload.name
  end
end