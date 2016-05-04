require 'spec_helper'
require 'collective'

describe Collective::Collectors::TrackJS do
  let(:env_api_key) { ENV["TRACKJS_API_KEY"] }
  let(:env_customer_id) { ENV["TRACKJS_CUSTOMER_ID"] }

  before do
    @collector = Collective::Collectors::TrackJS.new nil, {
      :api_key => env_api_key,
      :customer_id => env_customer_id
    }
  end

  context 'when no errors are returned' do
    let(:errors) { 0 }
    let(:page) { 1 }
    let(:page_size) { 250 }
    let(:has_more) { false }
    let(:response) { trackjs_response errors, page, page_size, has_more }

    fit 'logs an error count of 0' do
      stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
        .with(:query => {"page" => page, "size" => page_size})
        .to_return(:body => response.to_s, :status => 200)

      expect { @collector.collect }.to output('/count=0/').to_stdout
      expect(
        a_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors").with(:query => {"page" => page, "size" => page_size})
      ).to have_been_made
    end
  end

  context 'when we try and use the collect function' do
    let!(:metadata) { trackjs_metadata }
    let!(:resp) { trackjs_response 2 }

    it 'does stuff (test test)' do
      # expect(Collective::Collector).to receive(:instrument)
      @collector.collect
      p "trackjs metadata"
      pp metadata
      p "trackjs response"
      pp resp
    end
  end
end
