# frozen_string_literal: true

module Bayarcash
  # Small helpers that reproduce PHP string/array semantics the gateway relies on.
  module Util
    module_function

    # Cast a value to a string exactly the way PHP's `implode`/`(string)` cast does.
    #
    # This matters for byte-compatible checksum generation: `nil` becomes an empty
    # string, booleans become "1"/"" and everything else uses its string form.
    #
    # @param value [Object]
    # @return [String]
    def php_string(value)
      case value
      when nil    then ""
      when true   then "1"
      when false  then ""
      else value.to_s
      end
    end

    # Whether a decoded JSON value is "falsy" in the PHP sense.
    #
    # Mirrors PHP's `json_decode($body, true) ?: $body` short-circuit so that empty
    # or falsy payloads fall back to the raw response body.
    #
    # @param value [Object]
    # @return [Boolean]
    def php_falsy?(value)
      case value
      when nil, false then true
      when 0, 0.0     then true
      when "", "0"    then true
      when Array, Hash then value.empty?
      else false
      end
    end

    # URL-encode a component the way PHP's `urlencode` does (spaces become "+").
    #
    # @param value [Object]
    # @return [String]
    def url_encode(value)
      URI.encode_www_form_component(php_string(value))
    end

    # Build a URL-encoded query string, reproducing PHP's `http_build_query`
    # (RFC1738 encoding, bracket notation for nested arrays and hashes).
    #
    # @param params [Hash]
    # @param prefix [String, nil]
    # @return [String]
    def build_query(params, prefix = nil)
      parts = []

      params.each do |key, value|
        composed_key = prefix ? "#{prefix}[#{key}]" : key.to_s

        case value
        when Hash
          nested = build_query(value, composed_key)
          parts << nested unless nested.empty?
        when Array
          value.each_with_index do |item, index|
            if item.is_a?(Hash) || item.is_a?(Array)
              nested = build_query({ index => item }, composed_key)
              parts << nested unless nested.empty?
            else
              parts << "#{url_encode("#{composed_key}[#{index}]")}=#{url_encode(item)}"
            end
          end
        else
          parts << "#{url_encode(composed_key)}=#{url_encode(value)}"
        end
      end

      parts.join("&")
    end

    # Parse a JSON string, returning nil on failure instead of raising.
    #
    # @param body [String]
    # @return [Object, nil]
    def safe_json(body)
      JSON.parse(body)
    rescue JSON::ParserError, TypeError
      nil
    end
  end
end
