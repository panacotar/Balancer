class UsersController < ApplicationController
  before_action :authenticate_user!


  def dashboard 
    authorize User
    @transactions = current_user.transactions
    @shareholders = current_user.shareholders
    current_user.projects
    @user = current_user
  end

  def show
  #contract action if user get funded and not
  end
end
