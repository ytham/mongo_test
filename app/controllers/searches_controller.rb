class SearchesController < ApplicationController
  def index
    @searches = Search.all.reverse.first(20)
    @search = Search.new
    respond_to do |format|
      format.html
    end
  end

  def create
    @rillow = Rillow.new('X1-ZWz1bgh3iq3si3_af1tq')
    @search = Search.create(params[:search])
    @search.coordinates = Geocoder.coordinates(@search.address)
    result = @rillow.get_demographics(city: @search.city, state: @search.state).to_json
    @search.median_home_price = get_median_home_price(result)
    @search.median_income = get_median_income(result)
    @search.score = calculate_score(@search.median_income, @search.median_home_price)
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

  private

    def get_median_home_price(result)
      median_home_price = JSON(result)["response"][0]["pages"][0]["page"][0]["tables"][0]["table"][0]["data"][0]["attribute"][1]["values"][0]["city"][0]["value"][0]["content"]
      if median_home_price.blank?
        median_home_price = JSON(result)["response"][0]["pages"][0]["page"][0]["tables"][0]["table"][0]["data"][0]["attribute"][1]["values"][0]["city"][0]["value"][0]["content"]
      end
      median_home_price
    end

    def get_median_income(result)
      median_income = JSON(result)["response"][0]["pages"][0]["page"][2]["tables"][0]["table"][0]["data"][0]["attribute"][0]["values"][0]["city"][0]["value"][0]["content"]
      if median_income.blank?
        median_income = JSON(result)["response"][0]["pages"][0]["page"][2]["tables"][0]["table"][0]["data"][0]["attribute"][0]["values"][0]["city"][0]["value"][0]["content"]
      end
      median_income
    end

    def calculate_score(income, home_price)
      score = (100 * (((income.to_f/12) - (home_price.to_f/360))) / 3273).to_i
    end

end
