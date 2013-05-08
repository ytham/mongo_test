class SearchesController < ApplicationController
  def index
    @searches = Search.all
    @search = Search.new
    respond_to do |format|
      format.html
    end
  end

  def create
    @search = Search.create(params[:search])
    @search.coordinates = Geocoder.coordinates(@search.address)
    if @search.save
      redirect_to @search
    else
      redirect_to root_url
    end
  end

  def show
    @search = Search.find(params[:id])
    respond_to do |format|
      format.html
      format.json
    end
  end

  def destroy
    @search = Search.find(params[:id])
    respond_to do |format|
      format.js
    end
  end
end
