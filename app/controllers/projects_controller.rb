class ProjectsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[show index]

  def show
    @project = Project.find(params[:id])
    authorize @project
    @campaign = Campaign.new
  end

  def new
    @project = Project.new
    authorize @project
  end

  def create
    @project = Project.new(project_params)
    authorize @project
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
    @project.user = current_user
    @project.update(project_params)
    redirect_to project_path(@project)
  end

  def destroy
    authorize @project
    @project.destroy
  end


  private

  def project_params
    params.require(:project).permit(:project_name, :category, :pitch, :target)
  end
end
