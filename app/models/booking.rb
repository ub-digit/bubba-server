class Booking < ActiveRecord::Base
  belongs_to :booking_object
  self.primary_key = 'id'

  def self.time_to_date(timestamp)
    timestamp.to_date
  end

  def self.time_to_numeric(timestamp)
    timestamp.strftime("%H.%M").to_f
  end

  def timestamp(time_float)
    Time.parse(sprintf("%2.2f", time_float).gsub(/\./,':'))
  end

  def timestamp_start
    timestamp(pass_start)
  end

  def update_query(username, signature, new_status)
    "UPDATE bokning "+
      "SET bokad_barcode = #{Booking.sanitize(username)}, bokad = true, "+
      "    status = #{new_status}, kommentar = #{Booking.sanitize(signature)} "+
      "WHERE oid = #{self.id} AND bokad = false AND status = 1"
  end

  def book(username, signature, metadata)
    new_status = 2
    if !metadata[:current_time]
      metadata[:current_time] = Time.now
    end
    if metadata[:employee]
      new_status = 5 
    else
      if metadata[:current_time] >= timestamp_start-30.minutes &&
          metadata[:current_time] <= timestamp_start+30.minutes
        new_status = 4
      end
    end
    update_result = Booking.connection.execute(update_query(username, signature, new_status))
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

  def as_json(options = {})
    super(except: [:booked_by, :display_name]).merge({
      pass_start: timestring(pass_start),
      pass_stop: timestring(pass_stop), 
      signature: display_name
    })
  end
end
