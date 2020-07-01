class CampaignPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end


  def create?
    if record.user == user # fix after table campaig
      return true
    end
  end

  def update?
    record.user == user.admin
  end
end
