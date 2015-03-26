class BookingObjectsController < ApplicationController
  def index
    day = params[:day].to_i
    if params[:day] && (day < 0 || day > 6) 
      render json: {}, status: 400
    elsif params[:location_id]
      requested_date = Time.now.to_date
      requested_date += day if params[:day]
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
    day = params[:day].to_i 
    requested_date = Time.now.to_date
    requested_date += day if params[:day]
    obj = BookingObject.find_by_id(params[:id])

    if params[:day] && (day < 0 || day > 6) 
      render json: {}, status: 400
    elsif obj && params[:id] && params[:day]
      render json: {booking_object: obj.as_json(pass_day: requested_date)}
    else
      render json: {}, status: 404
    end
  end
end
