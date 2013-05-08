class Project
  include Mongoid::Document

  field :name, type: String
  field :priority, type: Integer

end
