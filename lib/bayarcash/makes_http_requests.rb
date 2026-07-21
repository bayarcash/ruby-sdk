# frozen_string_literal: true

module Bayarcash
  # HTTP transport for the Bayarcash API.
  #
  # Requests default to form-urlencoded bodies (matching the PHP SDK's Guzzle
  # `form_params` behaviour). To send a JSON body, pass a payload shaped like
  # `{ json: {...} }`. Non-2xx responses are mapped to typed errors.
  module MakesHttpRequests
    # @return [Faraday::Connection]
    attr_reader :connection

    # @param uri [String]
    # @return [Object] decoded response
    def get(uri)
      request(:get, uri)
    end

    # @param uri [String]
    # @param payload [Hash]
    # @return [Object] decoded response
    def post(uri, payload = {})
      request(:post, uri, payload)
    end

    # @param uri [String]
    # @param payload [Hash]
    # @return [Object] decoded response
    def put(uri, payload = {})
      request(:put, uri, payload)
    end

    # @param uri [String]
    # @param payload [Hash]
    # @return [Object] decoded response
    def delete(uri, payload = {})
      request(:delete, uri, payload)
    end

    # Retry a block until it returns a truthy value or the timeout elapses.
    #
    # @param timeout [Integer] seconds
    # @param sleep_seconds [Integer]
    # @yield the operation to retry
    # @return [Object] the truthy result
    # @raise [Bayarcash::TimeoutError] when the timeout elapses
    def retry_until(timeout, sleep_seconds = 5)
      start = Time.now.to_i

      loop do
        output = yield
        return output if output

        if Time.now.to_i - start < timeout
          sleep(sleep_seconds)
        else
          output = [] if output.nil? || output == false
          output = [output] unless output.is_a?(Array)
          raise Bayarcash::TimeoutError.new(output)
        end
      end
    end

    protected

    # Build (or rebuild) the Faraday connection for the current base URI/token/timeout.
    #
    # @return [Faraday::Connection]
    def build_connection
      @connection = Faraday.new(url: base_uri) do |faraday|
        faraday.headers["Authorization"] = "Bearer #{@token}"
        faraday.headers["Accept"] = "application/json"
        faraday.options.timeout = @timeout if @timeout
        faraday.adapter Faraday.default_adapter
      end
    end

    # Perform a request and decode the response, or map the error.
    def request(verb, uri, payload = {})
      payload ||= {}

      response = connection.run_request(verb.to_s.downcase.to_sym, uri, nil, nil) do |req|
        if json_payload?(payload)
          req.headers["Content-Type"] = "application/json"
          req.body = JSON.generate(payload[:json] || payload["json"])
        elsif !payload.empty?
          req.headers["Content-Type"] = "application/x-www-form-urlencoded"
          req.body = Bayarcash::Util.build_query(payload)
        end
      end

      status = response.status
      return handle_request_error(response) if status < 200 || status > 299

      parse_body(response.body.to_s)
    end

    # Map a non-2xx response to a typed error.
    def handle_request_error(response)
      body = response.body.to_s

      case response.status
      when 422
        parsed = Bayarcash::Util.safe_json(body)
        raise Bayarcash::ValidationError.new(parsed.is_a?(Hash) || parsed.is_a?(Array) ? parsed : {})
      when 404
        raise Bayarcash::NotFoundError.new
      when 400
        raise Bayarcash::FailedActionError, failed_action_message(body)
      when 429
        reset = response.headers["x-ratelimit-reset"]
        raise Bayarcash::RateLimitExceededError.new(reset ? reset.to_i : nil)
      else
        raise Bayarcash::Error, body
      end
    end

    private

    def json_payload?(payload)
      payload.is_a?(Hash) && (payload.key?(:json) || payload.key?("json"))
    end

    def parse_body(body)
      return body if body.nil? || body.empty?

      parsed = Bayarcash::Util.safe_json(body)
      return body if parsed.nil?
      return body if Bayarcash::Util.php_falsy?(parsed)

      parsed
    end

    def failed_action_message(body)
      decoded = Bayarcash::Util.safe_json(body)
      return body unless decoded.is_a?(Hash)

      message = decoded["message"] || decoded["error"] || body
      message = JSON.generate(message) if message.is_a?(Hash) || message.is_a?(Array)
      message
    end
  end
end
