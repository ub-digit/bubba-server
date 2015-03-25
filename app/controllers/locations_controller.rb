class LocationsController < ApplicationController
  def index
    locations = Location.where("sort_order IS NOT NULL")
    render json: {locations: locations}
  end
end
