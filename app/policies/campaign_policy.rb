class CampaignPolicy < ApplicationPolicy
  def create?
    user.present? && record.project.user == user
  end

  def update?
    create?
  end
end
