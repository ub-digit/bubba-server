class LocationsController < ApplicationController
  def index
    locations = Location.where("sort_order IS NOT NULL").where(id: BookingObject.pluck(:location_id))
    render json: {locations: locations}
  end
end
