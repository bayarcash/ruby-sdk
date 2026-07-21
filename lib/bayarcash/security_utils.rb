# frozen_string_literal: true

module Bayarcash
  # Constant-time string comparison helpers, mirroring PHP's `hash_equals`.
  #
  # This is the Ruby equivalent of `Rack::Utils.secure_compare` /
  # `ActiveSupport::SecurityUtils.secure_compare` and is used to compare callback
  # checksums so that verification is not vulnerable to timing attacks.
  module SecurityUtils
    module_function

    # Compare two strings in (length-dependent but content-) constant time.
    #
    # @param left [String]
    # @param right [String]
    # @return [Boolean] true only when the two strings are byte-for-byte equal
    def secure_compare(left, right)
      left = left.to_s
      right = right.to_s

      return false unless left.bytesize == right.bytesize

      if OpenSSL.respond_to?(:fixed_length_secure_compare)
        begin
          return OpenSSL.fixed_length_secure_compare(left, right)
        rescue StandardError
          # fall through to the manual implementation
        end
      end

      l = left.unpack("C*")
      res = 0
      right.each_byte { |byte| res |= byte ^ l.shift }
      res.zero?
    end
  end
end
