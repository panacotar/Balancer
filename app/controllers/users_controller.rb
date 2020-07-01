class UsersController < ApplicationController
  before_action :authenticate_user!

  def dashboard
  end

  def show
  #contract action if user get funded and not
  end
end
