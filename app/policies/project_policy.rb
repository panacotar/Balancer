class ProjectPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      scope.all
    end
  end

  def create?
    return true # anyone can create a project after login
  end

  def update?
    record.user == user
  end

  def destroy?
    user_is_admin?
  end

  private

  def user_is_admin?
    record.user == user.admin
  end
end
