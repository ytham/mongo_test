class SearchesController < ApplicationController
  include Calculations

  def index
    #@searches = Search.all.reverse.first(20)
    @searches = Search.all.sample(20)
    @search = Search.new
    respond_to do |format|
      format.html
    end
  end

  def create
    @search = Search.create(params[:search])
    @search.coordinates = Geocoder.coordinates(@search.input)
    input_type = detect_input_type(@search.input)
    if input_type == "citystatezip" # input for city, state or zip
      Rails.logger.debug ">>>> Input type is CITYSTATEZIP"
      region = get_demographics(-1, @search.city, @search.state)
      @search.median_home_price = get_median_home_price(region, false)
      @search.median_income = get_median_income(region, false)
      @search.score = calculate_score(@search.median_income, @search.median_home_price)
    else # all other (hopefully for regular addresses)
      Rails.logger.debug ">>>> Input type is REGULAR ADDRESS"
      region = query_address(@search.city, @search.state, @search.address)
      region_id = get_region_id(region)
      @search.neighborhood = get_neighborhood(region)
      demographics = get_demographics(region_id)
      @search.median_home_price = get_median_home_price(demographics)
      @search.median_income = get_median_income(demographics)
      @search.score = calculate_score(@search.median_income, @search.median_home_price)
    end
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

    def detect_input_type(input)
      if (input.length == 5 && input.to_i > 10000) || input[0].match(/^[[:alpha:]]$/) != nil
        return "citystatezip"
      else
        return "regular_address"
      end
    end

    def fetch_result(url_string)
      url = URI.parse(URI.escape(url_string))
      res = Net::HTTP.get_response(url)
      doc = XmlSimple.xml_in res.body
      json = JSON.pretty_generate(JSON.parse(doc.to_json))
      return json
    end

    def query_address(city, state, address=nil)
      address_url = ""
      if address.present?
        street_only = address.split(',')[0]
        street_only.gsub!(' ','+')
        address_url = "&address=#{street_only}"
      end
      city.gsub!(' ','+')
      state.gsub!(' ','+')
      citystate = "#{city},+#{state}"
      parsed_url = "http://www.zillow.com/webservice/GetSearchResults.htm?zws-id=X1-ZWz1bgh3iq3si3_af1tq#{address_url}&citystatezip=#{citystate}"
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

    def get_demographics(region_id, city=nil, state=nil)
      if region_id == -1 # Put it in city/state mode
        Rails.logger.debug "> get_demographics: Region ID mode is city/state - #{region_id}"
        city.gsub!(' ','+')
        state.gsub!(' ','+')
        option_state = "&state=#{state}"
        option_city = "&city=#{city}"
        option_region = ""
      else
        Rails.logger.debug "> get_demographics: Region ID mode is regular address - #{region_id}"
        option_state = ""
        option_city = ""
        option_region = "&regionid=#{region_id}"
      end
      parsed_url = "http://www.zillow.com/webservice/GetDemographics.htm?zws-id=X1-ZWz1bgh3iq3si3_af1tq#{option_state}#{option_city}#{option_region}"
      Rails.logger.debug ">>> get_demographics: #{parsed_url}"
      result = fetch_result(parsed_url)
      return result
    end


    def get_median_home_price(result, full_address=true)
      median_home_price = JSON(result).try(:[],"response").try(:[],0).try(:[],"pages").try(:[],0).try(:[],"page").try(:[],0).try(:[],"tables").try(:[],0).try(:[],"table").try(:[],0).try(:[],"data").try(:[],0).try(:[],"attribute").try(:[],1).try(:[],"values").try(:[],0).try(:[],"neighborhood").try(:[],0).try(:[],"value").try(:[],0).try(:[],"content")
      if median_home_price.blank? || full_address == false
        Rails.logger.debug ">>>>>> MEDIAN_HOME_PRICE if 1"
        median_home_price = JSON(result).try(:[],"response").try(:[],0).try(:[],"pages").try(:[],0).try(:[],"page").try(:[],0).try(:[],"tables").try(:[],0).try(:[],"table").try(:[],0).try(:[],"data").try(:[],0).try(:[],"attribute").try(:[],1).try(:[],"values").try(:[],0).try(:[],"city").try(:[],0).try(:[],"value").try(:[],0).try(:[],"content")
      end
      if median_home_price.blank?
        Rails.logger.debug ">>>>>> MEDIAN_HOME_PRICE if 2"
        median_home_price = JSON(result).try(:[],"response").try(:[],0).try(:[],"pages").try(:[],0).try(:[],"page").try(:[],0).try(:[],"tables").try(:[],0).try(:[],"table").try(:[],0).try(:[],"data").try(:[],0).try(:[],"attribute").try(:[],0).try(:[],"values").try(:[],0).try(:[],"city").try(:[],0).try(:[],"value").try(:[],0).try(:[],"content")
      end
      Rails.logger.debug ">>>>>> median_home_price: #{median_home_price}"
      median_home_price
    end

    def get_median_income(result, full_address=true)
      median_income = JSON(result).try(:[],"response").try(:[],0).try(:[],"pages").try(:[],0).try(:[],"page").try(:[],2).try(:[],"tables").try(:[],0).try(:[],"table").try(:[],0).try(:[],"data").try(:[],0).try(:[],"attribute").try(:[],1).try(:[],"values").try(:[],0).try(:[],"neighborhood").try(:[],0).try(:[],"value").try(:[],0).try(:[],"content")
      if median_income.blank? || median_income.to_f < 1.0 || full_address == false
        Rails.logger.debug ">>>>>> GET_MEDIAN_INCOME if 1"
        median_income = JSON(result).try(:[],"response").try(:[],0).try(:[],"pages").try(:[],0).try(:[],"page").try(:[],2).try(:[],"tables").try(:[],0).try(:[],"table").try(:[],0).try(:[],"data").try(:[],0).try(:[],"attribute").try(:[],1).try(:[],"values").try(:[],0).try(:[],"city").try(:[],0).try(:[],"value").try(:[],0).try(:[],"content")
      end
      if ( median_income.blank? || median_income.to_f < 1.0 ) && full_address == true
        Rails.logger.debug ">>>>>> GET_MEDIAN_INCOME if 2"
        median_income = JSON(result).try(:[],"response").try(:[],0).try(:[],"pages").try(:[],0).try(:[],"page").try(:[],2).try(:[],"tables").try(:[],0).try(:[],"table").try(:[],0).try(:[],"data").try(:[],0).try(:[],"attribute").try(:[],0).try(:[],"values").try(:[],0).try(:[],"neighborhood").try(:[],0).try(:[],"value").try(:[],0).try(:[],"content")
      end
      if median_income.blank? || median_income.to_f < 1.0
        Rails.logger.debug ">>>>>> GET_MEDIAN_INCOME if 3"
        median_income = JSON(result).try(:[],"response").try(:[],0).try(:[],"pages").try(:[],0).try(:[],"page").try(:[],2).try(:[],"tables").try(:[],0).try(:[],"table").try(:[],0).try(:[],"data").try(:[],0).try(:[],"attribute").try(:[],0).try(:[],"values").try(:[],0).try(:[],"city").try(:[],0).try(:[],"value").try(:[],0).try(:[],"content")
      end
      Rails.logger.debug ">>>>>> median_income: #{median_income}"
      median_income
    end

end
