# frozen_string_literal: true

require 'json'
require 'rest-client'
require 'base_model/model'

module BaseModel
  class RestConnection
    attr_reader :endpoint_url, :options

    def initialize(url = nil, opts = {})
      @endpoint_url = url || ENV['REST_ENDPOINT_URL']
      @options = opts
    end

    def test
      call(:get, '/')
    end

    def parse(response)
      response.headers[:content_type].include?('application/json') ? JSON.parse(response) : response
    end

    # Lowest level calls
    def call(http_method, url, payload = nil, headers = {}, &block)
      payload ||= {}
      headers = headers.merge options[:headers] if options[:headers]

      uri = URI.parse endpoint_url
      uri.path = url

      if http_method == :get
        query = uri.query.nil? ? payload : CGI.parse(uri.query).merge(payload)
        uri.query = URI.encode_www_form(query)
      end
      url = uri.to_s

      tries = 0
      begin
        headers['Accept'] ||= 'application/json'
        headers['Content-Type'] ||= 'application/json'
        response = RestClient::Request.execute(
          method: http_method,
          url: url,
          payload: http_method.to_sym == :get ? nil : payload,
          headers: headers,
          max_redirects: 0,
          &block
        )
        parse response
      rescue RestClient::ExceptionWithResponse, SocketError
        retry unless (tries +=1 ) > 1
        raise
      end
    end

    class << self
      def connect(url = nil, opts = {})
        connections << new(url, opts)
      end

      def connections
        @connections ||= []
      end
    end
  end
end
