class CampaignPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end


  def create?
    if record.user == user
      return true
    end
  end

  def update?
    record.user == user.admin
  end
end
