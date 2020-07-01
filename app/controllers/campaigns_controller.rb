class CampaignsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show]

  def index
    @campaigns = policy_scope(Campaign)
  end

  def show
    @campaign = Campaign.find(params[:id])
  end

  def new
    @project = Project.find(params[:project_id])
    @campaign = Campaign.new
    @campaign.project = @project
    authorize @campaign

  end

  def create
    @campaign = Campaign.new(campaign_params)
    @project = Project.find(params[:project_id])
    @campaign.project = @project
    authorize @campaign
    if @campaign.save
     redirect_to project_path(@project)
    else
      render :new
    end
  end



  private

  def campaign_params
    params.require(:campaign).permit(:name, :start_date, :end_date, :description)
    #p[:project_id] = project.id; #table project should be user_id not users_id
    #p
  end
end
