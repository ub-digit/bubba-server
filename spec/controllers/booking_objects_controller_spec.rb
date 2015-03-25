require 'rails_helper'

RSpec.describe BookingObjectsController, type: :controller do
  describe "get list" do
    it "should give error when not providing location_id" do
      get :index
      expect(response.status).to eq(400)
    end

    it "should give list of active objects for location_id for today" do
      get :index, location_id: 44
      expect(response.status).to eq(200)
      expect(json['booking_objects'].size).to eq(3)
    end

    it "should give an empty list location_id where no bookable times exist" do
      get :index, location_id: 47, day: 5
      expect(response.status).to eq(200)
      expect(json['booking_objects'].size).to eq(0)
    end

    it "should include booking data for objects" do
      get :index, location_id: 44, day: 5
      expect(json['booking_objects'][0]).to have_key('bookings')
      expect(json['booking_objects'][0]['bookings'].size).to eq(3)
    end 

    it "booking data should have timestamps in string format" do
      get :index, location_id: 44, day: 5
      expect(json['booking_objects'][0]['bookings'][0]['pass_start']).to eq('10:00')
      expect(json['booking_objects'][0]['bookings'][0]['pass_stop']).to eq('12:00')
    end
  end
end
