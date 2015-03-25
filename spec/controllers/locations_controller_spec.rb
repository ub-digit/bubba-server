require 'rails_helper'

RSpec.describe LocationsController, type: :controller do
  describe "get list" do
    it "should return a sorted list of libraries" do
      get :index
      expect(json['locations'].size).to eq(3)
      expect(json['locations'][0]['sort_order']).to eq(0)
      expect(json['locations'][1]['sort_order']).to eq(0)
      expect(json['locations'][2]['sort_order']).to eq(1)
    end
  end
end
