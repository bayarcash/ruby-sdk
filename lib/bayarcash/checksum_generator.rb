# frozen_string_literal: true

module Bayarcash
  # Checksum generation (HMAC-SHA256), byte-compatible with the gateway.
  #
  # The recipe is always the same: sort the payload hash by KEY ascending, join the
  # VALUES with "|", then HMAC-SHA256 with the merchant secret key and return the
  # lowercase hex digest.
  module ChecksumGenerator
    # Generic checksum primitive: ksort by key, implode values with "|", HMAC-SHA256.
    #
    # @param secret_key [String]
    # @param payload [Hash]
    # @return [String] lowercase hex HMAC-SHA256 digest
    def create_checksum_value(secret_key, payload)
      hmac_from_payload(secret_key, payload)
    end

    # Checksum for a payment intent request.
    #
    # Signs `payment_channel` (comma-joined when an array/multiple, empty when none),
    # `order_number`, `amount`, `payer_name` and `payer_email`.
    #
    # @param secret_key [String]
    # @param data [Hash]
    # @return [String]
    def create_payment_intent_checksum_value(secret_key, data)
      payment_channel = fetch_field(data, "payment_channel", [])
      payment_channel = [payment_channel] unless payment_channel.is_a?(Array)
      payment_channel = payment_channel.join(",")

      payload = {
        "payment_channel" => payment_channel,
        "order_number"    => fetch_field(data, "order_number"),
        "amount"          => fetch_field(data, "amount"),
        "payer_name"      => fetch_field(data, "payer_name"),
        "payer_email"     => fetch_field(data, "payer_email")
      }

      hmac_from_payload(secret_key, payload)
    end

    # Old typo version, kept for backward compatibility.
    #
    # @see #create_payment_intent_checksum_value
    def create_payment_inten_checksum_value(secret_key, data)
      create_payment_intent_checksum_value(secret_key, data)
    end

    # Checksum for an FPX Direct Debit enrolment request.
    #
    # @param secret_key [String]
    # @param data [Hash]
    # @return [String]
    def create_fpx_direct_debit_enrolment_checksum_value(secret_key, data)
      payload = {
        "order_number"           => fetch_field(data, "order_number"),
        "amount"                 => fetch_field(data, "amount"),
        "payer_name"             => fetch_field(data, "payer_name"),
        "payer_email"            => fetch_field(data, "payer_email"),
        "payer_telephone_number" => fetch_field(data, "payer_telephone_number"),
        "payer_id_type"          => fetch_field(data, "payer_id_type"),
        "payer_id"               => fetch_field(data, "payer_id"),
        "application_reason"     => fetch_field(data, "application_reason"),
        "frequency_mode"         => fetch_field(data, "frequency_mode")
      }

      hmac_from_payload(secret_key, payload)
    end

    # Checksum for an FPX Direct Debit maintenance request.
    #
    # @param secret_key [String]
    # @param data [Hash]
    # @return [String]
    def create_fpx_direct_debit_maintenance_checksum_value(secret_key, data)
      payload = {
        "amount"                 => fetch_field(data, "amount"),
        "payer_email"            => fetch_field(data, "payer_email"),
        "payer_telephone_number" => fetch_field(data, "payer_telephone_number"),
        "application_reason"     => fetch_field(data, "application_reason"),
        "frequency_mode"         => fetch_field(data, "frequency_mode")
      }

      hmac_from_payload(secret_key, payload)
    end

    private

    # Sort the payload by key, join stringified values with "|", HMAC-SHA256.
    def hmac_from_payload(secret_key, payload)
      payload_string = payload
                       .sort_by { |key, _| key.to_s }
                       .map { |_, value| Bayarcash::Util.php_string(value) }
                       .join("|")

      OpenSSL::HMAC.hexdigest("SHA256", Bayarcash::Util.php_string(secret_key), payload_string)
    end

    # Read a field from a hash that may use string or symbol keys.
    def fetch_field(data, key, default = nil)
      return data[key] if data.key?(key)

      symbol = key.to_sym
      return data[symbol] if data.key?(symbol)

      default
    end
  end
end
