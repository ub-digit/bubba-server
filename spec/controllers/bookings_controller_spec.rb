require 'rails_helper'

RSpec.describe BookingsController, type: :controller do
  before :each do
    WebMock.disable_net_connect!
    @obj = BookingObject.find_by_id(1)
    @pass = @obj.bookings.first
    @pass1 = @obj.bookings[0]
    @pass2 = @obj.bookings[1]
    @pass3 = @obj.bookings[2]
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
      put :update, id: @pass.id, username: '1234567890', password: '0987654321', signature: 'Test', cmd: 'book'
      expect(response.status).to eq(401)
      expect(json['error']['code']).to eq('AUTH_ERROR')
    end

    it "should return SIGN_ERROR if signature is missing" do
      put :update, id: @pass.id, username: '1234567890', password: '1111122222', cmd: 'book'
      expect(response.status).to eq(400)
      expect(json['error']['code']).to eq('SIGN_ERROR')
    end

    it "should return NOT_FOUND_ERROR if pass is missing" do
      put :update, id: 99999999, username: '1234567890', password: '1111122222', signature: 'Test student', cmd: 'book'
      expect(response.status).to eq(404)
      expect(json['error']['code']).to eq('NOT_FOUND_ERROR')
    end

    it "should return PASS_UNAVAIL_ERROR if pass was booked" do
      put :update, id: @pass.id, username: '1234567890', password: '1111122222', signature: 'Test student', cmd: 'book'
      expect(response.status).to eq(200)
      expect(json).to have_key('booking')
      expect(json['booking']['booked']).to eq(true)
      put :update, id: @pass.id, username: '1234567891', password: '2222211111', signature: 'Test employee', cmd: 'book'
      expect(response.status).to eq(400)
      expect(json['error']['code']).to eq('PASS_UNAVAIL_ERROR')
    end

    it "should accept a booking for an available pass by non-employee" do
      put :update, id: @pass.id, username: '1234567890', password: '1111122222', signature: 'Test student', cmd: 'book'
      expect(response.status).to eq(200)
      expect(json).to have_key('booking')
      expect(json['booking']['booked']).to eq(true)
      expect(json['booking']['signature']).to eq("Test student")
      expect(json['booking']['status']).to_not eq(1)
      expect(json['booking']['status']).to_not eq(5)
    end

    it "should not accept the third booking for the same user on the same day" do
      put :update, id: @pass1, username: '1234567890', password: '1111122222', signature: 'Test student', cmd: 'book'
      expect(response.status).to eq(200)
      put :update, id: @pass2, username: '1234567890', password: '1111122222', signature: 'Test student', cmd: 'book'
      expect(response.status).to eq(200)
      put :update, id: @pass3, username: '1234567890', password: '1111122222', signature: 'Test student', cmd: 'book'
      expect(response.status).to eq(400)
      expect(json['error']['code']).to eq('PASS_LIMIT_ERROR')
    end
  end
end
