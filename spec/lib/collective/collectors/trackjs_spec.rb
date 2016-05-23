require 'spec_helper'
require 'collective'
require 'active_support/core_ext/numeric/time'

describe Collective::Collectors::TrackJS do
  let(:env_api_key) { ENV["TRACKJS_API_KEY"] }
  let(:env_customer_id) { ENV["TRACKJS_CUSTOMER_ID"] }
  let(:page_size) { 250 }
  let(:page) { 1 }
  let(:no_errors) { 0 }
  let(:empty_response) { trackjs_response errors: no_errors, total_errors: no_errors, page: page, page_size: page_size }

  before do
    @collector = Collective::Collectors::TrackJS.new(
      :api_key => env_api_key,
      :customer_id => env_customer_id
    )
  end

  context 'when no errors are returned' do
    let(:errors) { 0 }
    let(:response) { trackjs_response errors: errors, total_errors: errors, page: page, page_size: page_size }

    it 'logs an error count of 0' do
      stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
        .with(:query => {"page" => page, "size" => page_size, "application" => "r101-frontend"})
        .to_return(
          :body => response.to_json,
          :status => 200,
          :headers => {'Content-Type' => 'application/json'}
        )
      stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
        .with(:query => {"page" => page, "size" => page_size, "application" => "r101-marketing"})
        .to_return(
          :body => response.to_json,
          :status => 200,
          :headers => {'Content-Type' => 'application/json'}
        )

      expect(Metrics).to receive(:instrument).with('trackjs.url.errors', 0, hash_including(:source => "r101-frontend"))
      expect(Metrics).to receive(:instrument).with('trackjs.url.errors', 0, hash_including(:source => "r101-marketing"))
      @collector.collect
      expect(
        a_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors").with(:query => {"page" => page, "size" => page_size, "application" => "r101-frontend"})
      ).to have_been_made
      expect(
        a_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors").with(:query => {"page" => page, "size" => page_size, "application" => "r101-marketing"})
      ).to have_been_made
    end
  end

  context 'when less than a page of errors are returned' do
    let(:error_count) { 45 }
    let(:metadata) { trackjs_metadata total_count: error_count, page: page, page_size: page_size, has_more: false }
    let(:response) { trackjs_response errors: error_count, total_errors: error_count, page: page, page_size: page_size }

    context 'when none of the errors have been logged before' do
      context 'all the errors are within the last @frequency seconds' do
        it 'logs all the errors returned' do
          stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
            .with(:query => {"page" => page, "size" => page_size, "application" => "r101-frontend"})
            .to_return(
              :body => response.to_json,
              :status => 200,
              :headers => {'Content-Type' => 'application/json'}
            )
          stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
            .with(:query => {"page" => page, "size" => page_size, "application" => "r101-marketing"})
            .to_return(
              :body => empty_response.to_json,
              :status => 200,
              :headers => {'Content-Type' => 'application/json'}
            )

          expect(Metrics).to receive(:instrument).with('trackjs.url.errors', error_count, hash_including(:source => "r101-frontend"))
          expect(Metrics).to receive(:instrument).with('trackjs.url.errors', 0, hash_including(:source => "r101-marketing"))
          @collector.collect
          expect(
            a_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors").with(:query => {"page" => page, "size" => page_size, "application" => "r101-frontend"})
          ).to have_been_made
          expect(
            a_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors").with(:query => {"page" => page, "size" => page_size, "application" => "r101-marketing"})
          ).to have_been_made
        end
      end

      context 'not all the errors are within the last @frequency seconds' do
        let(:old_error_count) { 7 }
        let(:old_timestamps) { old_error_count.times.map { 3.hours.ago.utc.strftime("%FT%T%:z") } }
        let(:old_errors) { old_error_count.times.map { |i| trackjs_error({timestamp: old_timestamps[i]}) } }
        let(:errors) { (error_count - old_error_count).times.map { trackjs_error} + old_errors }
        let(:response) { { "data" => errors, "metadata" => metadata } }

        it 'logs only the errors in the last @frequency s' do
          stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
            .with(:query => {"page" => page, "size" => page_size, "application" => "r101-frontend"})
            .to_return(
              :body => response.to_json,
              :status => 200,
              :headers => {'Content-Type' => 'application/json'}
            )
          stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
            .with(:query => {"page" => page, "size" => page_size, "application" => "r101-marketing"})
            .to_return(
              :body => empty_response.to_json,
              :status => 200,
              :headers => {'Content-Type' => 'application/json'}
            )

          expect(Metrics).to receive(:instrument).with('trackjs.url.errors', error_count - old_error_count, hash_including(:source => "r101-frontend"))
          expect(Metrics).to receive(:instrument).with('trackjs.url.errors', 0, hash_including(:source => "r101-marketing"))
          @collector.collect
          expect(
            a_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors").with(:query => {"page" => page, "size" => page_size, "application" => "r101-frontend"})
          ).to have_been_made
          expect(
            a_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors").with(:query => {"page" => page, "size" => page_size, "application" => "r101-marketing"})
          ).to have_been_made
        end
      end

      context 'none of the errors are within the last @frequency seconds' do
        let(:old_timestamps) { error_count.times.map { 3.hours.ago.utc.strftime("%FT%T%:z") } }
        let(:errors) { error_count.times.map { |i| trackjs_error({timestamp: old_timestamps[i]}) } }
        let(:response) { { "data" => errors, "metadata" => metadata } }

        it 'logs 0 errors' do
          stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
            .with(:query => {"page" => page, "size" => page_size, "application" => "r101-frontend"})
            .to_return(
              :body => response.to_json,
              :status => 200,
              :headers => {'Content-Type' => 'application/json'}
            )
          stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
            .with(:query => {"page" => page, "size" => page_size, "application" => "r101-marketing"})
            .to_return(
              :body => empty_response.to_json,
              :status => 200,
              :headers => {'Content-Type' => 'application/json'}
            )

          expect(Metrics).to receive(:instrument).with('trackjs.url.errors', 0, hash_including(:source => "r101-frontend"))
          expect(Metrics).to receive(:instrument).with('trackjs.url.errors', 0, hash_including(:source => "r101-marketing"))
          @collector.collect
          expect(
            a_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors").with(:query => {"page" => page, "size" => page_size, "application" => "r101-frontend"})
          ).to have_been_made
          expect(
            a_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors").with(:query => {"page" => page, "size" => page_size, "application" => "r101-marketing"})
          ).to have_been_made
        end
      end
    end

    context 'some of the errors have been logged before' do
      let(:old_error_count) { 5 }
      let(:new_error_count) { 3 }
      let(:old_errors) { old_error_count.times.map { trackjs_error } }
      let(:new_errors) { new_error_count.times.map { trackjs_error } }
      let(:all_errors) { new_errors + old_errors }
      let(:old_metadata) { trackjs_metadata total_count: old_error_count, page: page, page_size: page_size, has_more: false }
      let(:new_metadata) { trackjs_metadata total_count: (old_error_count + new_error_count), page: page, page_size: page_size, has_more: false }
      let(:old_response) { {"data" => old_errors, "metadata" => old_metadata} }
      let(:new_response) { {"data" => all_errors, "metadata" => new_metadata} }

      before do
        stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
          .with(:query => {"page" => page, "size" => page_size, "application" => "r101-frontend"})
          .to_return(
            :body => empty_response.to_json,
            :status => 200,
            :headers => {'Content-Type' => 'application/json'}
          )
        stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
          .with(:query => {"page" => page, "size" => page_size, "application" => "r101-marketing"})
          .to_return(
            :body => old_response.to_json,
            :status => 200,
            :headers => {'Content-Type' => 'application/json'}
          )

        @collector.collect
      end

      it 'logs only the errors that have occurred since the last time logging happened' do
        stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
          .with(:query => {"page" => page, "size" => page_size, "application" => "r101-frontend"})
          .to_return(
            :body => empty_response.to_json,
            :status => 200,
            :headers => {'Content-Type' => 'application/json'}
          )
        stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
          .with(:query => {"page" => page, "size" => page_size, "application" => "r101-marketing"})
          .to_return(
            :body => new_response.to_json,
            :status => 200,
            :headers => {'Content-Type' => 'application/json'}
          )

        expect(Metrics).to receive(:instrument).with('trackjs.url.errors', 0, hash_including(:source => "r101-frontend"))
        expect(Metrics).to receive(:instrument).with('trackjs.url.errors', new_errors.length, hash_including(:source => "r101-marketing"))
        @collector.collect
        expect(
          a_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors").with(:query => {"page" => page, "size" => page_size, "application" => "r101-frontend"})
        ).to have_been_made.times(2)
        expect(
          a_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors").with(:query => {"page" => page, "size" => page_size, "application" => "r101-marketing"})
        ).to have_been_made.times(2)
      end
    end
  end

  context 'when multiple pages of errors are returned' do
    let(:old_error_count) { 250 }
    let(:new_error_count) { 50 }
    let(:total_errors) { 800 }
    let(:page2) { 2 }

    context 'none of the errors have been logged before' do
      let(:recent_timestamps) { old_error_count.times.map { Time.now.utc.strftime("%FT%T%:z") } }
      let(:old_timestamps) { new_error_count.times.map { 3.hours.ago.utc.strftime("%FT%T%:z") } }
      let(:combined_timestamps) { recent_timestamps.slice(0, old_error_count - new_error_count) + old_timestamps }
      let(:response) { trackjs_response errors: old_error_count, timestamps: recent_timestamps, total_errors: total_errors, page: page, page_size: page_size }
      let(:response2) { trackjs_response errors: old_error_count, timestamps: combined_timestamps, total_errors: total_errors, page: page2, page_size: page_size }

      it 'logs only the errors that occurred in the last @frequency seconds' do
        stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
          .with(:query => {"page" => page, "size" => page_size, "application" => "r101-frontend"})
          .to_return(
            :body => response.to_json,
            :status => 200,
            :headers => {'Content-Type' => 'application/json'}
          )
        stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
          .with(:query => {"page" => page, "size" => page_size, "application" => "r101-marketing"})
          .to_return(
            :body => empty_response.to_json,
            :status => 200,
            :headers => {'Content-Type' => 'application/json'}
          )
        stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
          .with(:query => {"page" => page2, "size" => page_size, "application" => "r101-frontend"})
          .to_return(
            :body => response2.to_json,
            :status => 200,
            :headers => {'Content-Type' => 'application/json'}
          )
        stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
          .with(:query => {"page" => page2, "size" => page_size, "application" => "r101-marketing"})
          .to_return(
            :body => empty_response.to_json,
            :status => 200,
            :headers => {'Content-Type' => 'application/json'}
          )

        expect(Metrics).to receive(:instrument).with('trackjs.url.errors', 2 * page_size - old_timestamps.length, hash_including(:source => "r101-frontend"))
        expect(Metrics).to receive(:instrument).with('trackjs.url.errors', 0, hash_including(:source => "r101-marketing"))
        @collector.collect
        expect(
          a_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors").with(:query => {"page" => page, "size" => page_size, "application" => "r101-frontend"})
        ).to have_been_made.times(1)
        expect(
          a_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors").with(:query => {"page" => page, "size" => page_size, "application" => "r101-marketing"})
        ).to have_been_made.times(1)
      end
    end

    context 'some of the errors have been logged before' do
      let(:page1_errors) { old_error_count.times.map { trackjs_error } }
      let(:old_timestamps) { new_error_count.times.map { 3.hours.ago.utc.strftime("%FT%T%:z") } }
      let(:out_of_date_errors) { new_error_count.times.map { |i| trackjs_error({timestamp: old_timestamps[i]}) } }
      let(:page2_errors) { ((old_error_count - new_error_count).times.map { trackjs_error }) + out_of_date_errors }
      let(:new_errors) { new_error_count.times.map { trackjs_error } }
      let(:combined_errors) { (new_errors + page1_errors).first page_size }
      let(:old_metadata) { trackjs_metadata total_count: old_error_count, page: page, page_size: page_size, has_more: true }
      let(:combined_metadata) { trackjs_metadata total_count: (old_error_count + new_error_count), page: page2, page_size: page_size, has_more: true }
      let(:old_page1_response) { { "data" => page1_errors, "metadata" => old_metadata } }
      let(:old_page2_response) { { "data" => page2_errors, "metadata" => old_metadata } }
      let(:combined_response) { { "data" => combined_errors, "metadata" => combined_metadata } }

      before do
        stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
          .with(:query => {"page" => page, "size" => page_size, "application" => "r101-frontend"})
          .to_return(
            :body => old_page1_response.to_json,
            :status => 200,
            :headers => {'Content-Type' => 'application/json'}
          )
        stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
          .with(:query => {"page" => page, "size" => page_size, "application" => "r101-marketing"})
          .to_return(
            :body => empty_response.to_json,
            :status => 200,
            :headers => {'Content-Type' => 'application/json'}
          )
        stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
          .with(:query => {"page" => page2, "size" => page_size, "application" => "r101-frontend"})
          .to_return(
            :body => old_page2_response.to_json,
            :status => 200,
            :headers => {'Content-Type' => 'application/json'}
          )
        stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
          .with(:query => {"page" => page2, "size" => page_size, "application" => "r101-marketing"})
          .to_return(
            :body => empty_response.to_json,
            :status => 200,
            :headers => {'Content-Type' => 'application/json'}
          )
        @collector.collect
      end

      it 'logs only the errors that have occurred since the last time logging happened' do
        stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
          .with(:query => {"page" => page, "size" => page_size, "application" => "r101-frontend"})
          .to_return(
            :body => combined_response.to_json,
            :status => 200,
            :headers => {'Content-Type' => 'application/json'}
          )
        stub_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors")
          .with(:query => {"page" => page, "size" => page_size, "application" => "r101-marketing"})
          .to_return(
            :body => empty_response.to_json,
            :status => 200,
            :headers => {'Content-Type' => 'application/json'}
          )
        expect(Metrics).to receive(:instrument).with('trackjs.url.errors', new_errors.length, hash_including(:source => "r101-frontend"))
        expect(Metrics).to receive(:instrument).with('trackjs.url.errors', 0, hash_including(:source => "r101-marketing"))
        @collector.collect
        expect(
          a_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors").with(:query => {"page" => page, "size" => page_size, "application" => "r101-frontend"})
        ).to have_been_made.times(2)
        expect(
          a_request(:get, "https://api.trackjs.com/#{env_customer_id}/v1/errors").with(:query => {"page" => page, "size" => page_size, "application" => "r101-marketing"})
        ).to have_been_made.times(2)
      end
    end
  end
end
