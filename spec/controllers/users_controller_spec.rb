require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  # Mocked credentials:
  # valid student:    1234567890/1111122222
  # valid employee:   1234567891/2222211111
  # invalid:          1234567890/0987654321

  before :each do
    WebMock.disable_net_connect!
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

  describe "authenticate user" do
    it "should return true for valid user" do
      get :auth, username: '1234567890', password: '1111122222'
      expect(json['auth']).to be_truthy
    end

    it "should return false for invalid user" do
      get :auth, username: '1234567890', password: '0987654321'
      expect(response.status).to eq(401)
      expect(json['auth']).to be_falsey
    end
  end
end
