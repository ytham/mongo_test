class Search
  include Mongoid::Document
  include Geocoder::Model::Mongoid
  geocoded_by :input do |obj,results|
    if geo = results.first
      obj.address = geo.address
      obj.city = geo.city
      obj.state = geo.state
      obj.zip = geo.postal_code
      obj.country = geo.country_code
    end
  end

  after_validation :geocode

  field :coordinates, type: Array
  field :input
  field :address, type: String
  field :neighborhood, type: String
  field :city, type: String
  field :state, type: String
  field :zip, type: String
  field :country, type: String
  field :region_id, type: Integer
  field :median_income, type: Integer
  field :median_home_price, type: Integer
  field :score, type: Integer

  validates_presence_of :input
end
