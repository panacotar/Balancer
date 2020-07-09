class CampaignsController < ApplicationController

  skip_before_action :authenticate_user!, only: %i[index show]


  def index
    @projects = policy_scope(Project)
    @last_campaign = policy_scope(Campaign).last
    if params[:query].present?
      @campaigns = policy_scope(Campaign.search_by_name_and_description(params[:query]))
      if @campaigns.present?
        @campaigns
      else
        redirect_to campaigns_path, notice: "No search results were found"
      end
    else
      @campaigns = policy_scope(Campaign)
    end
    @campaigns_list = @campaigns.reject{|camp| camp.id == @last_campaign.id }.shuffle
    @categories = Project.list_categories
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

  def edit
    @project = Project.find(params[:project_id])
    @campaign = Campaign.find(params[:id])
    authorize @campaign

  end

  def update
    @campaign = Campaign.find(params[:id])
    authorize @campaign
    @campaign.update(campaign_params)
    redirect_to campaigns_path(@campaigns)
  end

  private

  def campaign_params
    params.require(:campaign).permit(:name, :start_date, :end_date, :description, :investment_goal, :equity, :photo)
  end
end
