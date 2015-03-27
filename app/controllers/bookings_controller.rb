class BookingsController < ApplicationController
  def update
    username = params[:username]
    password = params[:password]
    signature = params[:signature]
    auth_status = Auth.authenticate(username, password)
    if !auth_status
      render json: {error: {code: 'AUTH_ERROR'}}, status: 401
    elsif signature.blank?
      render json: {error: {code: 'SIGN_ERROR'}}, status: 400
    else
      booking = Booking.find_by_id(params[:id])
      booking.book(username, signature, {employee: auth_status[:employee]})
      render json: {booking: booking}
    end
  end
end
