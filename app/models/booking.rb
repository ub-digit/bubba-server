class Booking < ActiveRecord::Base
  belongs_to :booking_object
  self.primary_key = 'id'

  def self.time_to_date(timestamp)
    timestamp.to_date
  end

  def self.time_to_numeric(timestamp)
    timestamp.strftime("%H.%M").to_f
  end
end
