class BookingsController < ApplicationController
  def index
    username = params[:username]
    password = params[:password]
    auth_status = User.authenticate(username, password)

    if !auth_status
      render json: {error: {code: 'AUTH_ERROR'}}, status: 401
      return
    end

    bookings = Booking.where(booked_by: username)
    bookings = bookings.select do |booking| 
      booking.timestamp_stop > Time.now
    end
    render json: {bookings: bookings.as_json(include_booking_object: true)}
  end

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

      if bookings_count > 1 
        render json: {error: {code: 'PASS_LIMIT_ERROR'}}, status: 400
        return
      end
  
      if !booking.book(username, signature, {employee: auth_status[:employee]})
        render json: {error: {code: 'PASS_UNAVAIL_ERROR'}}, status: 400
        return
      end
    end
    
    if cmd == 'confirm' || cmd == 'cancel'
      if booking.booked_by != username
        render json: {error: {code: 'AUTH_ERROR'}}, status: 401
        return
      end
    end

    if cmd == 'confirm'
      if booking.status != 3
        render json: {error: {code: 'PASS_UNCONFIRMABLE_ERROR'}}, status: 400
        return
      end      

      if !booking.confirm(username)
        render json: {error: {code: 'PASS_UNCONFIRMABLE_ERROR'}}, status: 400
        return
      end
    end

    if cmd == 'cancel'
      if [1,4,5].include?(booking.status)
        render json: {error: {code: 'PASS_UNCANCELABLE_ERROR'}}, status: 400
        return
      end      

      if !booking.cancel(username)
        render json: {error: {code: 'PASS_UNCANCELABLE_ERROR'}}, status: 400
        return
      end
    end

    render json: {booking: booking}
  end
end
