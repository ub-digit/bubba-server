class BookingsController < ApplicationController
  def update
    username = params[:username]
    password = params[:password]
    signature = params[:signature]
    cmd = params[:cmd]

    auth_status = User.authenticate(username, password)

    if !auth_status
      render json: {error: {code: 'AUTH_ERROR'}}, status: 401
      return
    end

    if signature.blank? && cmd == 'book'
      render json: {error: {code: 'SIGN_ERROR'}}, status: 400
      return
    end
    
    booking = Booking.find_by_id(params[:id])

    if !booking
      render json: {error: {code: 'NOT_FOUND_ERROR'}}, status: 404
      return
    end
      
    if cmd == 'book' 
      bookings_count = Booking.where(booked: true, booked_by: username, pass_day: booking.pass_day).count
    end

    if cmd == 'book' && bookings_count > 1 
      render json: {error: {code: 'PASS_LIMIT_ERROR'}}, status: 400
      return
    end
  
    if !booking.book(username, signature, {employee: auth_status[:employee]})
      render json: {error: {code: 'PASS_UNAVAIL_ERROR'}}, status: 400
      return
    end

    #if !booking.confirm

    render json: {booking: booking}

  end
end
