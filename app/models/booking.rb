# -*- coding: utf-8 -*-
class Booking < ActiveRecord::Base
  belongs_to :booking_object
  self.primary_key = 'id'

  def self.time_to_date(timestamp)
    timestamp.to_date
  end

  def self.time_to_numeric(timestamp)
    timestamp.strftime("%H.%M").to_f
  end

  def daystring
    pass_day.strftime("%Y-%m-%d")
  end

  def timestamp(time_float)
    parse_string = sprintf("%s %2.2f", daystring, time_float).gsub(/\./,':')
    Time.parse(parse_string)
  end

  def timestamp_start
    timestamp(pass_start)
  end

  def timestamp_stop
    timestamp(pass_stop)
  end

  def book_query(username, signature, new_status)
    "UPDATE bokning "+
      "SET bokad_barcode = #{Booking.sanitize(username)}, bokad = true, "+
      "    status = #{new_status}, kommentar = #{Booking.sanitize(signature)} "+
      "WHERE oid = #{self.id} AND bokad = false AND status = 1"
  end

  def confirm_query(username)
    "UPDATE bokning SET status = 4"+
      "WHERE oid = #{self.id} AND bokad = true AND status = 3 AND bokad_barcode = #{Booking.sanitize(username)}"
  end

  def cancel_query(username)
    "UPDATE bokning "+
      "SET status = 1, bokad = false, kommentar = NULL, bokad_barcode = NULL "+
      "WHERE oid = #{self.id} AND bokad = true AND status IN (2,3) AND bokad_barcode = #{Booking.sanitize(username)}"
  end

  # Book a pass with a signature
  #
  # Rules:
  # User is employee:
  #   status => 5 (Booked, confirmed, employee)
  # If today:
  #   if pass not started and starting within 30 minutes:
  #     status => 3 (Booked, unconfirmed, confirmable)
  #   if pass started, not yet finished:
  #     status => 4 (Booked, confirmed)
  #   if pass finished:
  #     UNAVAILABLE
  # else
  #   status => 2 (Booked, unconfirmed, unconfirmable)
  #
  def book(username, signature, metadata)
    new_status = 2
    if !metadata[:current_time]
      metadata[:current_time] = Time.now
    end
    if metadata[:employee]
      new_status = 5 
    else
      if metadata[:current_time] >= timestamp_start-30.minutes &&
          metadata[:current_time] <= timestamp_start
        new_status = 3
      elsif metadata[:current_time] > timestamp_start
        if metadata[:current_time] < timestamp_stop
          new_status = 4
        elsif metadata[:current_time] > timestamp_stop
          return false
        end
      end
    end

    update_result = Booking.connection.execute(book_query(username, signature, new_status))
    if update_result.cmd_tuples == 1
      self.reload
      return true
    else
      return false
    end
  end

  def confirm(username)
    update_result = Booking.connection.execute(confirm_query(username))
    if update_result.cmd_tuples == 1
      self.reload
      return true
    else
      return false
    end
  end

  def cancel(username)
    update_result = Booking.connection.execute(cancel_query(username))
    if update_result.cmd_tuples == 1
      self.reload
      return true
    else
      return false
    end
  end

  def timestring(time_float)
    timestamp(time_float).strftime("%H:%M")
  end

  def is_confirmable?
    status == 3
  end

  def is_cancelable?
    status == 2 || status == 3
  end

  def is_bookable?
    status == 1 && timestamp_stop >= Time.now
  end

  def as_json(options = {})
    data = super(except: [:booked_by, :display_name]).merge({
      pass_start: timestring(pass_start),
      pass_stop: timestring(pass_stop), 
      signature: display_name
    })
    data[:booking_object] = booking_object if options[:include_booking_object]
    data[:confirmable] = is_confirmable?
    data[:cancelable] = is_cancelable?
    data[:bookable] = is_bookable?
    data
  end
end
