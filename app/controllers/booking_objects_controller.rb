class BookingObjectsController < ApplicationController
  def index
    if params[:location_id]
      requested_date = Time.now.to_date
      requested_date += params[:day].to_i if params[:day]
      objs = BookingObject
        .where(location_id: params[:location_id])
        .where(active: true)
        .joins(:bookings)
        .where(bookings: {pass_day: requested_date})
        .distinct
      render json: {booking_objects: objs.as_json(pass_day: requested_date)}
    else
      render json: {}, status: 400
    end
  end

  def show
    requested_date = Time.now.to_date
    requested_date += params[:day].to_i if params[:day]
    obj = BookingObject.find_by_id(params[:id])
    if obj && params[:id] && params[:day]
      render json: {booking_object: obj.as_json(pass_day: requested_date)}
    else
      render json: {}, status: 404
    end
  end
end
