class CampaignsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[index show]

  def index
    @campaigns = policy_scope(Campaign)

    if params[:query].present?
      sql_query = " \
        campaings.name @@ :query \
        OR campaings.description @@ :query \
      "
      @campaings = Campaign.where(sql_query, query: "%#{params[:query]}%")
    else
      @campaings = Campaign.all
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
    params.require(:campaign).permit(:name, :start_date, :end_date, :description, :amount, :percentage, :photo)
  end
end
