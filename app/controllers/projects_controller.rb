class ProjectsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[show index]

  def index
    @projects = Project.all
  end

  def show
    @project = Project.find(params[:id])
    @campaign = Campaign.new
  end

  def new
    @project = Project.new
  end

  def create
    @project = Project.new(project_params)
    @project.owner = current_user
    if @project.save
      redirect_to project_path(@project)
    else
      render :new
    end
  end

  def edit
    @project = Project.find(params[:id])
  end

  def update
    @project = Project.find(params[:id])
    @project.update(project_params)

    redirect_to project_path(@project)
  end

  private

  def project_params
    params.require(:project).permit(:user_id, :project_name, :category, :pitch, :target, :photo)
  end
end
