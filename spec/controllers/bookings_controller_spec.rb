require 'rails_helper'

RSpec.describe BookingsController, type: :controller do
  before :each do
    WebMock.disable_net_connect!
    @obj = BookingObject.find_by_id(1)
    @pass = @obj.bookings.first
  end
  after :each do
    WebMock.allow_net_connect!
  end

  # Mocked credentials:
  # valid student:    1234567890/1111122222
  # valid employee:   1234567891/2222211111
  # invalid:          1234567890/0987654321

  describe "booking request" do
    before :each do
      stub_request(:get, "https://auth.example.com/")
        .with(query: {bar: '1234567890', pnr: '0987654321'})
        .to_return(:status => 200, :body => "-1", :headers => {})
      stub_request(:get, "https://auth.example.com/")
        .with(query: {bar: '1234567890', pnr: '1111122222'})
        .to_return(:status => 200, :body => "100", :headers => {})
      stub_request(:get, "https://auth.example.com/")
        .with(query: {bar: '1234567891', pnr: '2222211111'})
        .to_return(:status => 200, :body => "110", :headers => {})
    end

    it "should return AUTH_ERROR if credentials fail" do
      put :update, id: @pass.id, username: '1234567890', password: '0987654321', signature: 'Test'
      expect(response.status).to eq(401)
      expect(json['error']['code']).to eq('AUTH_ERROR')
    end

    it "should return SIGN_ERROR if signature is missing" do
      put :update, id: @pass.id, username: '1234567890', password: '1111122222'
      expect(response.status).to eq(400)
      expect(json['error']['code']).to eq('SIGN_ERROR')
    end

    it "should accept a booking for an available pass by non-employee" do
      put :update, id: @pass.id, username: '1234567890', password: '1111122222', signature: 'Test student'
      expect(response.status).to eq(200)
      expect(json).to have_key('booking')
      expect(json['booking']['booked']).to eq(true)
      expect(json['booking']['signature']).to eq("Test student")
      expect(json['booking']['status']).to_not eq(1)
      expect(json['booking']['status']).to_not eq(5)
    end
  end
end
