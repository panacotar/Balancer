class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home, :about ]

  def home
    @campaigns = policy_scope(Campaign)
    @projects = policy_scope(Project)
  end

  def about
  end
end
