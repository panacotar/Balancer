class CampaignPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def create?
    return unless record.project.user == user

    true
  end

  def update?
    record.project.user == user
  end
end
