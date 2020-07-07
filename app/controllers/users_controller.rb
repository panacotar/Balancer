class UsersController < ApplicationController
  before_action :authenticate_user!


  def dashboard 
    authorize User
    @transactions = current_user.transactions
    @shareholders = current_user.shareholders
    @user = current_user
    @projects = current_user.projects
    @order = current_user.orders
    @campaigns = current_user.campaigns
  end

  def show
  #contract action if user get funded and not
  end
end
