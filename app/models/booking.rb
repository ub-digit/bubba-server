class Booking < ActiveRecord::Base
  belongs_to :booking_object
  self.primary_key = 'id'

  def self.time_to_date(timestamp)
    timestamp.to_date
  end

  def self.time_to_numeric(timestamp)
    timestamp.strftime("%H.%M").to_f
  end

  def timestring(time_float)
    Time.parse(sprintf("%2.2f", time_float).gsub(/\./,':')).strftime("%H:%M")
  end

  def as_json(options = {})
    super(except: [:booked_by, :display_name]).merge({
      pass_start: timestring(pass_start),
      pass_stop: timestring(pass_stop), 
      signature: display_name
    })
  end
end
