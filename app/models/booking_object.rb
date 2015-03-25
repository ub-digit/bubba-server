class BookingObject < ActiveRecord::Base
  self.primary_key = 'id'
  has_many :bookings
  belongs_to :location

  def as_json(options = {})
    super.merge({
      bookings: bookings.where(pass_day: options[:pass_day]).order(:pass_start)
    })
  end
end
