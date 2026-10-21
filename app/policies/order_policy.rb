class OrderPolicy < ApplicationPolicy
  def create?
    user.present? && record.user == user
  end

  def show?
    create?
  end

  class Scope < Scope
    def resolve
      scope.where(user: user)
    end
  end
end
