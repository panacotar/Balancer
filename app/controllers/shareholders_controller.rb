class ShareholdersController < ApplicationController
  before_action :authenticate_user!

  def new
    authorize Shareholder

    last_pay = current_user.orders.last
    campaign = last_pay.campaign

    pledge_amount = last_pay.amount

    proj_percent = (campaign.equity * pledge_amount.to_i) / campaign.investment_goal

    new_shareholder = Shareholder.new(amount: pledge_amount,
                                      percentage: proj_percent,
                                      status: "Active",
                                      user: current_user,
                                      campaign: campaign)

    # shareholder will save, but percentage is Integer, so if it's 2.9, it will show 2
    if new_shareholder.save
      redirect_to successfulpledge_path
    else
      puts "error"
      redirect_to order_url(current_user.orders.last)
    end
  end

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

    @pledge_avail = campaign.investment_goal - pledged_before

    if pledge_amount > @pledge_avail
      return redirect_to project_path(project)
    end

    # calculate percent
    proj_percent = (campaign.equity * pledge_amount) / campaign.investment_goal

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
