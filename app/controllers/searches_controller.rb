class SearchesController < ApplicationController
  def index
    @searches = Search.all.reverse.first(20)
    @search = Search.new
    respond_to do |format|
      format.html
    end
  end

  def create
    @search = Search.create(params[:search])
    @search.coordinates = Geocoder.coordinates(@search.input)
    region = query_address(@search.address, @search.city, @search.state)
    region_id = get_region_id(region)
    @search.neighborhood = get_neighborhood(region)
    demographics = get_demographics(region_id)
    #result = @rillow.get_demographics(city: @search.city, state: @search.state).to_json
    @search.median_home_price = get_median_home_price(demographics)
    @search.median_income = get_median_income(demographics)
    @search.score = calculate_score(@search.median_income, @search.median_home_price)
    if @search.save
      redirect_to @search
    else
      redirect_to root_url
    end
  end

  def show
    @search = Search.find(params[:id])
    @new_search = Search.new
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

    def fetch_result(url_string)
      url = URI.parse(URI.escape(url_string))
      res = Net::HTTP.get_response(url)
      doc = XmlSimple.xml_in res.body
      json = JSON.pretty_generate(JSON.parse(doc.to_json))
      return json
    end

    def query_address(address, city, state)
      street_only = address.split(',')[0]
      street_only.gsub!(' ','+')
      city.gsub!(' ','+')
      state.gsub!(' ','+')
      citystate = "#{city},+#{state}"
      parsed_url = "http://www.zillow.com/webservice/GetSearchResults.htm?zws-id=X1-ZWz1bgh3iq3si3_af1tq&address=#{street_only}&citystatezip=#{citystate}"
      Rails.logger.debug ">>> get_region_id: #{parsed_url}"
      result = fetch_result(parsed_url)
      return result
    end

    def get_region_id(response)
      JSON(response).try(:[],'response').try(:[],0).try(:[],'results').try(:[],0).try(:[],'result').try(:[],0).try(:[],'localRealEstate').try(:[],0).try(:[],'region').try(:[],0).try(:[],'id')
    end

    def get_neighborhood(response)
      JSON(response).try(:[],'response').try(:[],0).try(:[],'results').try(:[],0).try(:[],'result').try(:[],0).try(:[],'localRealEstate').try(:[],0).try(:[],'region').try(:[],0).try(:[],'name')
    end

    def get_demographics(region_id)
      parsed_url = "http://www.zillow.com/webservice/GetDemographics.htm?zws-id=X1-ZWz1bgh3iq3si3_af1tq&regionid=#{region_id}"
      Rails.logger.debug ">>> get_demographics: #{parsed_url}"
      result = fetch_result(parsed_url)
      return result
    end


    def get_median_home_price(result)
      median_home_price = JSON(result).try(:[],"response").try(:[],0).try(:[],"pages").try(:[],0).try(:[],"page").try(:[],0).try(:[],"tables").try(:[],0).try(:[],"table").try(:[],0).try(:[],"data").try(:[],0).try(:[],"attribute").try(:[],1).try(:[],"values").try(:[],0).try(:[],"neighborhood").try(:[],0).try(:[],"value").try(:[],0).try(:[],"content")
      if median_home_price.blank?
        median_home_price = JSON(result).try(:[],"response").try(:[],0).try(:[],"pages").try(:[],0).try(:[],"page").try(:[],0).try(:[],"tables").try(:[],0).try(:[],"table").try(:[],0).try(:[],"data").try(:[],0).try(:[],"attribute").try(:[],1).try(:[],"values").try(:[],0).try(:[],"city").try(:[],0).try(:[],"value").try(:[],0).try(:[],"content")
      end
      median_home_price
    end

    def get_median_income(result)
      median_income = JSON(result).try(:[],"response").try(:[],0).try(:[],"pages").try(:[],0).try(:[],"page").try(:[],2).try(:[],"tables").try(:[],0).try(:[],"table").try(:[],0).try(:[],"data").try(:[],0).try(:[],"attribute").try(:[],1).try(:[],"values").try(:[],0).try(:[],"neighborhood").try(:[],0).try(:[],"value").try(:[],0).try(:[],"content")
      if median_income.blank? || median_income.to_f < 1.0
        median_income = JSON(result).try(:[],"response").try(:[],0).try(:[],"pages").try(:[],0).try(:[],"page").try(:[],2).try(:[],"tables").try(:[],0).try(:[],"table").try(:[],0).try(:[],"data").try(:[],0).try(:[],"attribute").try(:[],1).try(:[],"values").try(:[],0).try(:[],"city").try(:[],0).try(:[],"value").try(:[],0).try(:[],"content")
      end
      if median_income.blank? || median_income.to_f < 1.0
        median_income = JSON(result).try(:[],"response").try(:[],0).try(:[],"pages").try(:[],0).try(:[],"page").try(:[],2).try(:[],"tables").try(:[],0).try(:[],"table").try(:[],0).try(:[],"data").try(:[],0).try(:[],"attribute").try(:[],0).try(:[],"values").try(:[],0).try(:[],"neighborhood").try(:[],0).try(:[],"value").try(:[],0).try(:[],"content")
      end
      if median_income.blank? || median_income.to_f < 1.0
        median_income = JSON(result).try(:[],"response").try(:[],0).try(:[],"pages").try(:[],0).try(:[],"page").try(:[],2).try(:[],"tables").try(:[],0).try(:[],"table").try(:[],0).try(:[],"data").try(:[],0).try(:[],"attribute").try(:[],0).try(:[],"values").try(:[],0).try(:[],"city").try(:[],0).try(:[],"value").try(:[],0).try(:[],"content")
      end
      Rails.logger.debug ">>>>>> median_income #{median_income}"
      median_income
    end

    def calculate_score(income, home_price)
      score = (100 * (((income.to_f/12) - (home_price.to_f/360))) / 3273).to_i
    end

end
