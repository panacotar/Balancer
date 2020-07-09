class CampaignsController < ApplicationController

  skip_before_action :authenticate_user!, only: %i[index show]


  def index
    @projects = policy_scope(Project)
    if params[:query].present?
      @campaigns = policy_scope(Campaign.search_by_name_and_description(params[:query]))
      if @campaigns.present?
        @campaings
      else
        redirect_to campaigns_path, notice: "No search results were found"
      end
    else
      @campaigns = policy_scope(Campaign)
    end
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
    params.require(:campaign).permit(:name, :start_date, :end_date, :description, :investment_goal, :equity, :photo)
  end
end
