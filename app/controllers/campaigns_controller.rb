class CampaignsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[show index]

  def index
    @campaigns = Campaign.all
  end

  def show
    @campaign = Campaign.find(params[:id])
  end

  def new
    @project = Project.find(params[:project_id])
    @campaign = Campaign.new
  end

  def create
    @campaign = Campaign.new(campaign_params)

    @project = Project.find(params[:project_id])
    @campaign.project = @project
    @campaign.save
    redirect_to project_path(@project)
  end

  private

  def campaign_params
    params.require(:campaign).permit(:name, :start_date, :end_date, :description)
  end
end
