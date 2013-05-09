class Search
  include Mongoid::Document
  include Geocoder::Model::Mongoid
  geocoded_by :address do |obj,results|
    if geo = results.first
      obj.city = geo.city
      obj.state = geo.state
      obj.zip = geo.postal_code
      obj.country = geo.country_code
    end
  end

  after_validation :geocode

  field :coordinates, type: Array
  field :address
  field :city, type: String
  field :state, type: String
  field :zip, type: String
  field :country, type: String
  field :median_income, type: Integer
  field :median_home_price, type: Integer
  field :score, type: Integer

  validates_presence_of :address
end
