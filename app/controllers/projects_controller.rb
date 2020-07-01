class ProjectsController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[show index]

  def show
    @project = Project.find(params[:id])
    @campaign = Campaign.new
    authorize @project
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
