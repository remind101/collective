require 'spec_helper'
require 'collective'

describe Collective::Collectors::TrackJS do
  let(:env_api_key) { ENV["TRACKJS_API_KEY"] }
  let(:env_customer_id) { ENV["TRACKJS_CUSTOMER_ID"] }
  let(:page_size) { 250 }
  let(:page) { 1 }

  before do
    @collector = Collective::Collectors::TrackJS.new nil, {
      :api_key => env_api_key,
      :customer_id => env_customer_id
    }
  end

  context 'when no errors are returned' do
    let(:errors) { 0 }
    let(:response) { trackjs_response errors, errors, page, page_size }

    it 'logs an error count of 0' do
      stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
        .with(:query => {"page" => page, "size" => page_size})
        .to_return(
          :body => response.to_json,
          :status => 200,
          :headers => {'Content-Type' => 'application/json'}
        )

      expect(Metrics).to receive(:instrument).with('trackjs.url.errors', 0, any_args)
      @collector.collect
      expect(
        a_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors").with(:query => {"page" => page, "size" => page_size})
      ).to have_been_made
    end
  end

  context 'when less than a page of errors are returned' do
    let(:errors) { 45 }
    let(:response) { trackjs_response errors, errors, page, page_size }

    context 'when none of the errors have been logged before' do
      it 'logs all the errors returned' do
        stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
          .with(:query => {"page" => page, "size" => page_size})
          .to_return(
            :body => response.to_json,
            :status => 200,
            :headers => {'Content-Type' => 'application/json'}
          )

        expect(Metrics).to receive(:instrument).with('trackjs.url.errors', 45, any_args)
        @collector.collect
        expect(
          a_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors").with(:query => {"page" => page, "size" => page_size})
        ).to have_been_made
      end
    end

    context 'some of the errors have been logged before' do
      let(:old_error_count) { 5 }
      let(:new_error_count) { 3 }
      let(:old_errors) { old_error_count.times.map { trackjs_error } }
      let(:new_errors) { new_error_count.times.map { trackjs_error } }
      let(:all_errors) { new_errors + old_errors }
      let(:old_metadata) { trackjs_metadata old_error_count, page, page_size, false }
      let(:new_metadata) { trackjs_metadata (old_error_count + new_error_count), page, page_size, false }
      let(:old_response) { {"data" => old_errors, "metadata" => old_metadata} }
      let(:new_response) { {"data" => all_errors, "metadata" => new_metadata} }

      before do
        stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
          .with(:query => {"page" => page, "size" => page_size})
          .to_return(
            :body => old_response.to_json,
            :status => 200,
            :headers => {'Content-Type' => 'application/json'}
          )
        @collector.collect
      end

      it 'logs only the errors that have occurred since the last time logging happened' do
        stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
          .with(:query => {"page" => page, "size" => page_size})
          .to_return(
            :body => new_response.to_json,
            :status => 200,
            :headers => {'Content-Type' => 'application/json'}
          )
        expect(Metrics).to receive(:instrument).with('trackjs.url.errors', new_errors.length, any_args)
        @collector.collect
        expect(
          a_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors").with(:query => {"page" => page, "size" => page_size})
        ).to have_been_made.times(2)
      end
    end
  end

  context 'when more than maxPages pages of errors are returned' do
    let(:old_error_count) { 250 }
    let(:new_error_count) { 50 }
    let(:total_errors) { 800 }
    let(:page2) { 2 }

    context 'none of the errors have been logged before' do
      let(:response) { trackjs_response old_error_count, total_errors, page, page_size }
      let(:response2) { trackjs_response old_error_count, total_errors, page2, page_size }

      it 'logs maxPage * page size errors' do
        stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
          .with(:query => {"page" => page, "size" => page_size})
          .to_return(
            :body => response.to_json,
            :status => 200,
            :headers => {'Content-Type' => 'application/json'}
          )
        stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
          .with(:query => {"page" => page2, "size" => page_size})
          .to_return(
            :body => response2.to_json,
            :status => 200,
            :headers => {'Content-Type' => 'application/json'}
          )

        expect(Metrics).to receive(:instrument).with('trackjs.url.errors', page_size, any_args)
        @collector.collect
        expect(
          a_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors").with(:query => {"page" => page, "size" => page_size})
        ).to have_been_made.times(1)
      end
    end

    context 'some of the errors have been logged before' do
      let(:old_errors) { old_error_count.times.map { trackjs_error } }
      let(:new_errors) { new_error_count.times.map { trackjs_error } }
      let(:combined_errors) { (new_errors + old_errors).first page_size }
      let(:old_metadata) { trackjs_metadata old_error_count, page, page_size, true }
      let(:combined_metadata) { trackjs_metadata (old_error_count + new_error_count), page, page_size, true }
      let(:old_response) { {"data" => old_errors, "metadata" => old_metadata } }
      let(:combined_response) { {"data" => combined_errors, "metadata" => combined_metadata } }

      before do
        stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
          .with(:query => {"page" => page, "size" => page_size})
          .to_return(
            :body => old_response.to_json,
            :status => 200,
            :headers => {'Content-Type' => 'application/json'}
          )
        stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
          .with(:query => {"page" => page2, "size" => page_size})
          .to_return(
            :body => old_response.to_json,
            :status => 200,
            :headers => {'Content-Type' => 'application/json'}
          )
        @collector.collect
      end

      it 'logs only the errors that have occurred since the last time logging happened' do
        stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
          .with(:query => {"page" => page, "size" => page_size})
          .to_return(
            :body => combined_response.to_json,
            :status => 200,
            :headers => {'Content-Type' => 'application/json'}
          )
        expect(Metrics).to receive(:instrument).with('trackjs.url.errors', new_errors.length, any_args)
        @collector.collect
        expect(
          a_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors").with(:query => {"page" => page, "size" => page_size})
        ).to have_been_made.times(2)
      end
    end
  end
end
