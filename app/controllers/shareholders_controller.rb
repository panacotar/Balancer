class ShareholdersController < ApplicationController
  before_action :authenticate_user!
  
  def create
    project = Project.find(params[:project_id])
    authorize Shareholder

    pledge_amount = params[:pledge_amount].to_i
    campaign = project.campaigns.first
    if campaign.nil?
      return redirect_to project_path(project)
    end

    # calculate the amount that was pledged before ...
    pledged_before = 0
    campaign.shareholders.each do |sh|
      pledged_before += sh.amount
    end
    pledge_avail = campaign.amount - pledged_before

    if (pledge_amount > pledge_avail)
      return redirect_to project_path(project)
    end

    # calculate percent
    proj_percent = (campaign.percentage * pledge_amount) / campaign.amount

    # create the shareholder 
    pledge = Shareholder.new
    pledge.amount = pledge_amount
    pledge.percentage = proj_percent
    pledge.status = "Active"
    pledge.user = current_user
    pledge.campaign = campaign

    pledge.save!

    redirect_to successfulpledge_path
  end
end
