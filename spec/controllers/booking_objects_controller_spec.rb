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
  end
end
