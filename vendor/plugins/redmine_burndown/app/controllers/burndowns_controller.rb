require 'gchart'

class BurndownsController < ApplicationController
  unloadable
  menu_item :roadmap

  before_filter :find_version_and_project, :authorize, :only => [:show]

  def show
    @chart = BurndownChart.new(@version)
  end

private
  def find_version_and_project
    @version = Version.find(params[:id])
    @project = @version.project
  end
end