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
    if @project.save
      direct_to project_show_path(@project)
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
    p = params.require(:project).permit(:project_name, :category, :pitch, :target)
    p[:users_id] = current_user.id; #table project should be user_id not users_id
    p
  end

end
