class BookingsController < ApplicationController
  def update
    username = params[:username]
    password = params[:password]
    signature = params[:signature]
    auth_status = User.authenticate(username, password)
    if !auth_status
      render json: {error: {code: 'AUTH_ERROR'}}, status: 401
    elsif signature.blank?
      render json: {error: {code: 'SIGN_ERROR'}}, status: 400
    else
      booking = Booking.find_by_id(params[:id])
      if !booking
        render json: {error: {code: 'NOT_FOUND_ERROR'}}, status: 404
      else
        bookings_count = Booking.where(booked: true, booked_by: username, pass_day: booking.pass_day).count
        if bookings_count > 1 
          render json: {error: {code: 'PASS_LIMIT_ERROR'}}, status: 400
        elsif booking.book(username, signature, {employee: auth_status[:employee]})
          render json: {booking: booking}
        else
          render json: {error: {code: 'PASS_UNAVAIL_ERROR'}}, status: 400
        end
      end
    end
  end
end
