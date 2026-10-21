class ShareholdersController < ApplicationController
  # Legacy URLs remain reachable, but only a verified Stripe event can create a pledge.
  def new
    authorize Shareholder
    redirect_to project_path(params[:project_id]), notice: 'Demo pledges are confirmed after Stripe test checkout.'
  end

  def create
    authorize Shareholder
    redirect_to project_path(params[:project_id]), alert: 'Please pledge through demo checkout.'
  end
end
