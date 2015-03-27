require 'rails_helper'

RSpec.describe Booking, type: :model do
  describe "book pass" do
    before :each do
      @obj = BookingObject.find_by_id(1)
      @pass = @obj.bookings.first
      @time_long_before_pass = @pass.timestamp_start - 2.hours
      @time_close_to_pass = @pass.timestamp_start - 15.minutes
    end

    it "should book a pass that is available for a non-employee" do
      expect(@pass.booked).to be_falsey
      @pass.book("1234567890", "Test Signature", {current_time: @time_long_before_pass, employee: false})
      expect(@pass.booked).to be_truthy
      expect(@pass.booked_by).to eq('1234567890')
      expect(@pass.status).to eq(2)
    end

    it "should book a pass that is available for an employee" do
      expect(@pass.booked).to be_falsey
      @pass.book("1234567891", "Employee Signature", {current_time: @time_long_before_pass, employee: true})
      expect(@pass.booked).to be_truthy
      expect(@pass.booked_by).to eq('1234567891')
      expect(@pass.status).to eq(5)
    end

    it "should automatically confirm a booked pass when close to pass start time" do
      expect(@pass.booked).to be_falsey
      @pass.book("1234567890", "Test Signature", {current_time: @time_close_to_pass, employee: false})
      expect(@pass.booked).to be_truthy
      expect(@pass.booked_by).to eq('1234567890')
      expect(@pass.status).to eq(4)
    end
  end
end
