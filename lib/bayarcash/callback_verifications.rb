# frozen_string_literal: true

module Bayarcash
  # Callback verification, one verifier per callback type.
  #
  # Each verifier reconstructs the exact payload the gateway signs, computes the
  # HMAC-SHA256 checksum and compares it against the supplied `checksum` using a
  # constant-time comparison (see {Bayarcash::SecurityUtils.secure_compare}).
  module CallbackVerifications
    # Verify a direct-debit bank-approval callback.
    #
    # @param callback_data [Hash]
    # @param secret_key [String]
    # @return [Boolean]
    def verify_direct_debit_bank_approval_callback_data(callback_data, secret_key)
      payload = {
        "record_type"              => cb(callback_data, "record_type"),
        "approval_date"            => cb(callback_data, "approval_date"),
        "approval_status"          => cb(callback_data, "approval_status"),
        "mandate_id"               => cb(callback_data, "mandate_id"),
        "mandate_reference_number" => cb(callback_data, "mandate_reference_number"),
        "order_number"             => cb(callback_data, "order_number"),
        "payer_bank_code_hashed"   => cb(callback_data, "payer_bank_code_hashed"),
        "payer_bank_code"          => cb(callback_data, "payer_bank_code"),
        "payer_bank_account_no"    => cb(callback_data, "payer_bank_account_no"),
        "application_type"         => cb(callback_data, "application_type")
      }

      verify_callback(callback_data, payload, secret_key)
    end

    # Verify a direct-debit authorization callback.
    #
    # NOTE: this payload MUST include `application_type` (the gateway signs it);
    # omitting it causes every genuine authorization callback to fail verification.
    #
    # @param callback_data [Hash]
    # @param secret_key [String]
    # @return [Boolean]
    def verify_direct_debit_authorization_callback_data(callback_data, secret_key)
      payload = {
        "record_type"               => cb(callback_data, "record_type"),
        "transaction_id"            => cb(callback_data, "transaction_id"),
        "mandate_id"                => cb(callback_data, "mandate_id"),
        "application_type"          => cb(callback_data, "application_type"),
        "exchange_reference_number" => cb(callback_data, "exchange_reference_number"),
        "exchange_transaction_id"   => cb(callback_data, "exchange_transaction_id"),
        "order_number"              => cb(callback_data, "order_number"),
        "currency"                  => cb(callback_data, "currency"),
        "amount"                    => cb(callback_data, "amount"),
        "payer_name"                => cb(callback_data, "payer_name"),
        "payer_email"               => cb(callback_data, "payer_email"),
        "payer_bank_name"           => cb(callback_data, "payer_bank_name"),
        "status"                    => cb(callback_data, "status"),
        "status_description"        => cb(callback_data, "status_description"),
        "datetime"                  => cb(callback_data, "datetime")
      }

      verify_callback(callback_data, payload, secret_key)
    end

    # Verify a direct-debit transaction callback.
    #
    # @param callback_data [Hash]
    # @param secret_key [String]
    # @return [Boolean]
    def verify_direct_debit_transaction_callback_data(callback_data, secret_key)
      payload = {
        "record_type"              => cb(callback_data, "record_type"),
        "batch_number"             => cb(callback_data, "batch_number"),
        "mandate_id"               => cb(callback_data, "mandate_id"),
        "mandate_reference_number" => cb(callback_data, "mandate_reference_number"),
        "transaction_id"           => cb(callback_data, "transaction_id"),
        "datetime"                 => cb(callback_data, "datetime"),
        "reference_number"         => cb(callback_data, "reference_number"),
        "amount"                   => cb(callback_data, "amount"),
        "status"                   => cb(callback_data, "status"),
        "status_description"       => cb(callback_data, "status_description"),
        "cycle"                    => cb(callback_data, "cycle")
      }

      verify_callback(callback_data, payload, secret_key)
    end

    # Verify a transaction callback (sent to your callback_url).
    #
    # @param callback_data [Hash]
    # @param secret_key [String]
    # @return [Boolean]
    def verify_transaction_callback_data(callback_data, secret_key)
      payload = {
        "record_type"               => cb(callback_data, "record_type"),
        "transaction_id"            => cb(callback_data, "transaction_id"),
        "exchange_reference_number" => cb(callback_data, "exchange_reference_number"),
        "exchange_transaction_id"   => cb(callback_data, "exchange_transaction_id"),
        "order_number"              => cb(callback_data, "order_number"),
        "currency"                  => cb(callback_data, "currency"),
        "amount"                    => cb(callback_data, "amount"),
        "payer_name"                => cb(callback_data, "payer_name"),
        "payer_email"               => cb(callback_data, "payer_email"),
        "payer_bank_name"           => cb(callback_data, "payer_bank_name"),
        "status"                    => cb(callback_data, "status"),
        "status_description"        => cb(callback_data, "status_description"),
        "datetime"                  => cb(callback_data, "datetime")
      }

      verify_callback(callback_data, payload, secret_key)
    end

    # Verify a return-url callback (payer redirect).
    #
    # @param callback_data [Hash]
    # @param secret_key [String]
    # @return [Boolean]
    def verify_return_url_callback_data(callback_data, secret_key)
      payload = {
        "transaction_id"            => cb(callback_data, "transaction_id"),
        "exchange_reference_number" => cb(callback_data, "exchange_reference_number"),
        "exchange_transaction_id"   => cb(callback_data, "exchange_transaction_id"),
        "order_number"              => cb(callback_data, "order_number"),
        "currency"                  => cb(callback_data, "currency"),
        "amount"                    => cb(callback_data, "amount"),
        "payer_bank_name"           => cb(callback_data, "payer_bank_name"),
        "status"                    => cb(callback_data, "status"),
        "status_description"        => cb(callback_data, "status_description")
      }

      verify_callback(callback_data, payload, secret_key)
    end

    # Verify a pre-transaction callback (sent before the transaction record).
    #
    # @param callback_data [Hash]
    # @param secret_key [String]
    # @return [Boolean]
    def verify_pre_transaction_callback_data(callback_data, secret_key)
      payload = {
        "record_type"               => cb(callback_data, "record_type"),
        "exchange_reference_number" => cb(callback_data, "exchange_reference_number"),
        "order_number"              => cb(callback_data, "order_number")
      }

      verify_callback(callback_data, payload, secret_key)
    end

    private

    # Reconstruct the checksum from the payload and compare it, constant-time,
    # against the checksum supplied in the callback data.
    def verify_callback(callback_data, payload, secret_key)
      provided_checksum = cb(callback_data, "checksum") || ""

      payload_string = payload
                       .sort_by { |key, _| key.to_s }
                       .map { |_, value| Bayarcash::Util.php_string(value) }
                       .join("|")

      computed = OpenSSL::HMAC.hexdigest(
        "SHA256",
        Bayarcash::Util.php_string(secret_key),
        payload_string
      )

      Bayarcash::SecurityUtils.secure_compare(computed, provided_checksum.to_s)
    end

    # Read a callback field that may use string or symbol keys; nil when absent.
    def cb(callback_data, key)
      return callback_data[key] if callback_data.key?(key)

      symbol = key.to_sym
      return callback_data[symbol] if callback_data.key?(symbol)

      nil
    end
  end
end
