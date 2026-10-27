require 'test_helper'

class CampaignPolicyTest < ActiveSupport::TestCase
  def test_scope
  end

  def test_show
  end

  def test_create
  end

  def test_update
    owner = create_user(email: 'campaign-owner@example.com', phone: '5550003333')
    other = create_user(email: 'campaign-other@example.com', phone: '5550004444')
    campaign = create_campaign_for(owner, name: 'Policy Round')

    assert CampaignPolicy.new(owner, campaign).update?
    assert_not CampaignPolicy.new(other, campaign).update?
  end

  def test_destroy
  end
end
