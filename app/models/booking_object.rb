class BookingObject < ActiveRecord::Base
  self.primary_key = 'id'
  has_many :bookings
  belongs_to :location
end
