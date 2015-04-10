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

  # Mocked credentials:
  # valid student:    1234567890/1111122222
  # valid employee:   1234567891/2222211111
  # invalid:          1234567890/0987654321

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

  after :each do
    WebMock.allow_net_connect!
  end

  describe "show list of bookings" do
    context "wrong credentials" do
      it "should return AUTH_ERROR when credentials are wrong" do
        get :index, username: '1234567890', password: '0987654321'
        expect(response.status).to eq(401)
        expect(json['error']['code']).to eq("AUTH_ERROR")
      end
    end

    context "correct credentials" do
      before :each do
        Time.spec_force_time(@pass1.timestamp_start - 8.hours)
        put :update, id: @pass1, username: '1234567890', password: '1111122222', signature: 'Test student', cmd: 'book'
        put :update, id: @pass2, username: '1234567890', password: '1111122222', signature: 'Test student', cmd: 'book'
      end

      after :each do
        Time.spec_reset_forced_time
      end

      it "should return list of future passes booked by user" do
        Time.spec_force_time(@pass1.timestamp_start)
        get :index, username: '1234567890', password: '1111122222'
        expect(json['bookings']).to_not be_empty
      end

      it "should not list passes that have expired" do
        Time.spec_force_time(@pass1.timestamp_start)
        get :index, username: '1234567890', password: '1111122222'
        expect(json['bookings'].count).to be(2)
        Time.spec_force_time(@pass1.timestamp_stop+1.minute)
        get :index, username: '1234567890', password: '1111122222'
        expect(json['bookings'].count).to be(1)
      end

      it "should include booking object data in pass lite item" do
        Time.spec_force_time(@pass1.timestamp_start)
        get :index, username: '1234567890', password: '1111122222'
        expect(json['bookings'][0]['booking_object']['name']).to_not be_nil
      end

      it "should indicate confirmability on passes" do
        Time.spec_force_time(@pass1.timestamp_start - 2.hours)
        ActiveRecord::Base.connection.execute("UPDATE bokning SET status = 3 WHERE oid = #{@pass1.id}")
        get :index, username: '1234567890', password: '1111122222'
        expect(json['bookings'][0]['confirmable']).to be_truthy
        expect(json['bookings'][1]['confirmable']).to be_falsey
      end

      it "should indicate cancelability on passes" do
        Time.spec_force_time(@pass1.timestamp_start - 2.hours)
        ActiveRecord::Base.connection.execute("UPDATE bokning SET status = 4 WHERE oid = #{@pass2.id}")
        get :index, username: '1234567890', password: '1111122222'
        expect(json['bookings'][0]['cancelable']).to be_truthy
        expect(json['bookings'][1]['cancelable']).to be_falsey
      end
    end
  end

  describe "booking request" do
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

  describe "confirm request" do
    before :each do
      put :update, id: @pass1, username: '1234567890', password: '1111122222', signature: 'Test student', cmd: 'book'
      put :update, id: @pass2, username: '1234567890', password: '1111122222', signature: 'Test student', cmd: 'book'
      ActiveRecord::Base.connection.execute("UPDATE bokning SET status = 3 WHERE oid = #{@pass1.id}")
    end
    
    after :each do
      Time.spec_reset_forced_time
    end

    context "bad data" do
      it "should return AUTH_ERROR with bad credentials" do
        put :update, id: @pass1, username: '1234567890', password: '0987654321', cmd: 'confirm'
        expect(response.status).to eq(401)
        expect(json['error']['code']).to eq('AUTH_ERROR')
      end

      it "should return AUTH_ERROR if pass booked by someone else" do
        put :update, id: @pass1, username: '1234567891', password: '2222211111', cmd: 'confirm'
        expect(response.status).to eq(401)
        expect(json['error']['code']).to eq('AUTH_ERROR')
      end

      it "should return NOT_FOUND_ERROR if pass not found" do
        put :update, id: 9999999999999999999, username: '1234567891', password: '2222211111', cmd: 'confirm'
        expect(response.status).to eq(404)
        expect(json['error']['code']).to eq('NOT_FOUND_ERROR')
      end

      it "should return PASS_UNCONFIRMABLE_ERROR if pass not in confirmable status" do
        put :update, id: @pass2, username: '1234567890', password: '1111122222', cmd: 'confirm'
        expect(response.status).to eq(400)
        expect(json['error']['code']).to eq('PASS_UNCONFIRMABLE_ERROR')
      end
    end

    context "proper data" do
      it "should confirm pass and return updated pass when requested with proper data" do
        put :update, id: @pass1, username: '1234567890', password: '1111122222', cmd: 'confirm'
        expect(response.status).to eq(200)
        expect(json['booking']['status']).to eq(4)
      end
    end
  end

  describe "cancel request" do
    before :each do
      Time.spec_force_time(@pass1.timestamp_start-1.hour)
      put :update, id: @pass1, username: '1234567890', password: '1111122222', signature: 'Test student', cmd: 'book'
      Time.spec_force_time(@pass2.timestamp_start-1.hour)
      put :update, id: @pass2, username: '1234567890', password: '1111122222', signature: 'Test student', cmd: 'book'
      ActiveRecord::Base.connection.execute("UPDATE bokning SET status = 3 WHERE oid = #{@pass1.id}")
    end
    
    after :each do
      Time.spec_reset_forced_time
    end

    context "bad data" do
      it "should return AUTH_ERROR with bad credentials" do
        put :update, id: @pass1, username: '1234567890', password: '0987654321', cmd: 'cancel'
        expect(response.status).to eq(401)
        expect(json['error']['code']).to eq('AUTH_ERROR')
      end

      it "should return AUTH_ERROR if pass booked by someone else" do
        put :update, id: @pass1, username: '1234567891', password: '2222211111', cmd: 'cancel'
        expect(response.status).to eq(401)
        expect(json['error']['code']).to eq('AUTH_ERROR')
      end

      it "should return NOT_FOUND_ERROR if pass not found" do
        put :update, id: 9999999999999999999, username: '1234567891', password: '2222211111', cmd: 'cancel'
        expect(response.status).to eq(404)
        expect(json['error']['code']).to eq('NOT_FOUND_ERROR')
      end

      it "should return PASS_UNCANCELABLE_ERROR if pass not in cancelable status" do
        put :update, id: @pass1, username: '1234567890', password: '1111122222', cmd: 'confirm'
        put :update, id: @pass1, username: '1234567890', password: '1111122222', cmd: 'cancel'
        expect(response.status).to eq(400)
        expect(json['error']['code']).to eq('PASS_UNCANCELABLE_ERROR')
      end
    end

    context "proper data" do
      it "should cancel pass and return updated pass for booked, unconfirmed/unconfirmable pass" do
        Time.spec_force_time(@pass2.timestamp_start-1.hour)
        put :update, id: @pass2, username: '1234567890', password: '1111122222', cmd: 'cancel'
        expect(response.status).to eq(200)
        expect(json['booking']['status']).to eq(1)
        expect(json['booking']['booked']).to eq(false)
        expect(json['booking']['booked']).to eq(false)
        expect(json['booking']['signature']).to be_blank
      end

      it "should cancel pass and return updated pass for booked, unconfirmed/confirmable pass" do
        Time.spec_force_time(@pass1.timestamp_start-1.hour)
        put :update, id: @pass1, username: '1234567890', password: '1111122222', cmd: 'cancel'
        expect(response.status).to eq(200)
        expect(json['booking']['status']).to eq(1)
        expect(json['booking']['booked']).to eq(false)
        expect(json['booking']['booked']).to eq(false)
        expect(json['booking']['signature']).to be_blank
      end
    end
  end
end
