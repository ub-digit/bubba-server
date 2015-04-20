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

    it "should give error when day isnt valid" do
      get :index, location_id: 3, day: 8
      expect(response.status).to eq(400)
    end
  end

  describe "get a room" do
    it "should return a room with details of pass and equipment" do
      get :show, id: 3, day: 5
      expect(json['booking_object']).to have_key('bookings')
      expect(json['booking_object']['bookings'].size).to eq(3)
      expect(json['booking_object']['bookings'][0]['pass_start']).to eq('10:00')
      expect(json['booking_object']['bookings'][0]['pass_stop']).to eq('12:00')
    end

    it "should give error when not supplying day" do
      get :show, id: 3
      expect(response.status).to eq(404)
    end

    it "should give error when supplying non-existent booking object" do
      get :show, id: 999999, day: 5
      expect(response.status).to eq(404)
    end

    it "should mark as unbookable for pass that has passed" do
      Time.spec_reset_forced_time
      get :show, id: 3, day: 0
      pass = Booking.find_by_id(json['booking_object']['bookings'][0]['id'])
      Time.spec_force_time(pass.timestamp_stop + 1.minute)
      get :show, id: 3, day: 0
      expect(json['booking_object']['bookings'][0]['bookable']).to be_falsey
      expect(json['booking_object']['bookings'][1]['bookable']).to be_truthy
    end

    it "should mark as expired for pass that has passed" do
      Time.spec_reset_forced_time
      get :show, id: 3, day: 0
      pass = Booking.find_by_id(json['booking_object']['bookings'][0]['id'])
      Time.spec_force_time(pass.timestamp_stop + 1.minute)
      get :show, id: 3, day: 0
      expect(json['booking_object']['bookings'][0]['expired']).to be_truthy
      expect(json['booking_object']['bookings'][1]['expired']).to be_falsey
    end
    it "should return a signature" do
      get :show, id: 3, day: 5
      expect(json['booking_object']['bookings'][0]).to have_key('signature')
    end

    it "should give error when day isnt valid" do
      get :show, id: 3, day: 8
      expect(response.status).to eq(400)
    end
  end
end
