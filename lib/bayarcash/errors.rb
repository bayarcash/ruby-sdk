# frozen_string_literal: true

module Bayarcash
  # Base class for every error raised by the SDK.
  class Error < StandardError; end

  # Raised on HTTP 422 responses. Carries the validation error payload from the API.
  class ValidationError < Error
    # @return [Hash, Array] the raw errors payload returned by the API
    attr_reader :errors

    def initialize(errors = {})
      @errors = errors || {}
      super("The given data failed to pass validation.")
    end
  end

  # Raised on HTTP 404 responses.
  class NotFoundError < Error
    def initialize(message = "The resource you are looking for could not be found.")
      super
    end
  end

  # Raised on HTTP 400 responses. The message holds the reason returned by the API.
  class FailedActionError < Error; end

  # Raised on HTTP 429 responses. Exposes the rate-limit reset timestamp when available.
  class RateLimitExceededError < Error
    # @return [Integer, nil] unix timestamp at which the rate limit resets
    attr_reader :rate_limit_resets_at

    def initialize(rate_limit_reset = nil)
      @rate_limit_resets_at = rate_limit_reset
      super("Too Many Requests.")
    end
  end

  # Raised by the optional {Bayarcash::MakesHttpRequests#retry_until} helper after a timeout.
  class TimeoutError < Error
    # @return [Array] the output collected before the timeout
    attr_reader :output

    def initialize(output = [])
      @output = output
      super("Script timed out while waiting for the process to complete.")
    end
  end
end
