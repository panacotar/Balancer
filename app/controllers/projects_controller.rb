class ProjectsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[show index]

  def show
    @project = Project.find(params[:id])
    authorize @project
    @pledged_before = 0
    @allow_pledges = false
    @pledge_remaining = 0

    @campaign = nil
    if !@project.campaigns.empty?
      @campaign = @project.campaigns.first

      @campaign.shareholders.each do |sh|
        @pledged_before += sh.amount
      end

      if @pledged_before < @campaign.investment_goal
        @allow_pledges = true
      end

      @pledge_remaining = @campaign.investment_goal - @pledged_before
    end
  end

  def new
    @project = Project.new
    authorize @project
  end

  def create
    @project = Project.new(project_params)
    authorize @project
    params[:commit] == "Save Progress" ? @project[:status] = false : @project[:status] = true
    @project[:user_id] = current_user.id

    if @project.save
      redirect_to project_path(@project)
    else
      render :new
    end
  end

  def edit
    @project = Project.find(params[:id])
    authorize @project
  end

  def update
    @project = Project.find(params[:id])
    authorize @project
    @project.update(project_params)
    redirect_to project_path(@project)
  end

  def destroy
    authorize @project
    @project.destroy
  end

  private

  def project_params
    params.require(:project).permit(:project_name, :category, :pitch, :vision, :target, :photo)
  end
end
