class ShareholdersController < ApplicationController
  before_action :authenticate_user!
  
  def create
    project = Project.find(params[:project_id])
    authorize Shareholder

    pledge_percent = params[:pledge_percent].to_i
    if pledge_percent < 1 || pledge_percent > 100
      return redirect_to project_path(project)
    end

    campaign = project.campaigns.first

    # calculate the amount that was pledged before ...
    pledged_before = 0
    campaign.shareholders.each do |sh|
      pledged_before += sh.amount
    end
    pledge_avail = campaign.amount - pledged_before

    # amount pledged now
    pledged_now = (campaign.amount / 100) * pledge_percent

    if (pledged_now > pledge_avail)
      return redirect_to project_path(project)
    end

    # create the shareholder 
    pledge = Shareholder.new
    pledge.amount = pledged_now
    pledge.percentage = (campaign.percentage / 100) * pledge_percent
    pledge.status = "Active"
    pledge.user = current_user
    pledge.campaign = campaign

    pledge.save!

    redirect_to dashboard_path
  end
end
