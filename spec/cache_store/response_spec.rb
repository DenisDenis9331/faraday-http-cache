require 'spec_helper'

describe Faraday::CacheStore::Response do

  describe 'freshness' do
    it "is fresh if the response still has some time to live" do
      date = 200.seconds.ago.httpdate
      headers = { 'Cache-Control' => 'max-age=400', 'Date' => date }
      response = Faraday::CacheStore::Response.new(:response_headers => headers)

      response.should be_fresh
    end

    it "isn't fresh when the ttl has expired" do
      date = 500.seconds.ago.httpdate
      headers = { 'Cache-Control' => 'max-age=400', 'Date' => date }
      response = Faraday::CacheStore::Response.new(:response_headers => headers)

      response.should_not be_fresh
    end
  end

  describe 'max age calculation' do

    it 'uses the shared max age directive when present' do
      headers = { 'Cache-Control' => 's-maxage=200, max-age=0'}
      response = Faraday::CacheStore::Response.new(:response_headers => headers)
      response.max_age.should == 200
    end

    it 'uses the max age directive when present' do
      headers = { 'Cache-Control' => 'max-age=200'}
      response = Faraday::CacheStore::Response.new(:response_headers => headers)
      response.max_age.should == 200
    end

    it "fallsback to the expiration date leftovers" do
      headers = { 'Expires' => (Time.now + 100).httpdate, 'Date' => Time.now.httpdate }
      response = Faraday::CacheStore::Response.new(:response_headers => headers)
      response.max_age.should == 100
    end

    it "returns nil when there's no information to calculate the max age" do
      response = Faraday::CacheStore::Response.new()
      response.max_age.should be_nil
    end
  end

  describe 'age calculation' do
    it "uses the 'Age' header if it's present" do
      response = Faraday::CacheStore::Response.new(:response_headers => { 'Age' => '3' })
      response.age.should == 3
    end

    it "calculates the time from the 'Date' header" do
      date = 3.seconds.ago.httpdate
      response = Faraday::CacheStore::Response.new(:response_headers => { 'Date' => date })
      response.age.should == 3
    end

    it "sets the 'Date' header if isn't present and calculates the age" do
      response = Faraday::CacheStore::Response.new(:response_headers => {})
      response.age.should == 0
      response.date.should be_present
    end
  end

  describe 'time to live calculation' do
    it "returns the time to live based on the max age limit" do
      date = 200.seconds.ago.httpdate
      headers = { 'Cache-Control' => 'max-age=400', 'Date' => date }
      response = Faraday::CacheStore::Response.new(:response_headers => headers)
      response.ttl.should == 200
    end
  end

  describe "response unboxing" do
    subject { described_class.new(:status => 200, :response_headers => {}, :body => 'Hi!') }
    let(:response) { subject.to_response }

    it 'returns a Faraday::Response' do
      response.should be_a Faraday::Response
    end

    it 'merges the status code' do
      response.status.should == 200
    end

    it 'merges the headers' do
      response.headers.should == {}
    end

    it 'merges the body' do
      response.body.should == "Hi!"
    end
  end
end