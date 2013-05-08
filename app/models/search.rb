class Search
  include Mongoid::Document
  include Geocoder::Model::Mongoid
  geocoded_by :address
  after_validation :geocode

  field :coordinates, type: Array
  field :address
end
