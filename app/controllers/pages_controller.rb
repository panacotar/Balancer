class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home, :about ]

  def home
    @campaigns = policy_scope(Campaign)
  end

  def about
  end
end
