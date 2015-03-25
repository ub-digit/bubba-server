class Location < ActiveRecord::Base
  self.primary_key = 'id'
  has_many :booking_objects

end
