# frozen_string_literal: true

module Bayarcash
  # The Bayarcash API client.
  #
  # Mirrors the public surface of the official PHP SDK while remaining idiomatic
  # Ruby and framework-agnostic.
  #
  # @example
  #   client = Bayarcash::Client.new("YOUR_API_TOKEN")
  #   client.use_sandbox.set_api_version("v3")
  #   intent = client.create_payment_intent(data)
  #   redirect_to intent.url
  class Client
    include MakesHttpRequests
    include ChecksumGenerator
    include CallbackVerifications
    include FpxDirectDebitPaymentIntent
    include ManualBankTransfer

    # Payment channels
    FPX               = 1
    MANUAL_TRANSFER   = 2
    FPX_DIRECT_DEBIT  = 3
    FPX_LINE_OF_CREDIT = 4
    DUITNOW_DOBW      = 5
    DUITNOW_QR        = 6
    SPAYLATER         = 7
    BOOST_PAYFLEX     = 8
    QRISOB            = 9
    QRISWALLET        = 10
    NETS              = 11
    CREDIT_CARD       = 12
    ALIPAY            = 13
    WECHATPAY         = 14
    PROMPTPAY         = 15
    TOUCH_N_GO        = 16
    BOOST_WALLET      = 17
    GRABPAY           = 18
    GRABPL            = 19
    SHOPEE_PAY        = 21

    # Allowed filter keys for {#get_all_transactions}.
    ALLOWED_TRANSACTION_FILTERS = %w[
      order_number status payment_channel exchange_reference_number payer_email
    ].freeze

    # @return [String] the API token
    attr_reader :token
    # @return [Integer] request timeout in seconds
    attr_reader :timeout
    # @return [Boolean] whether the sandbox environment is in use
    attr_reader :sandbox
    # @return [String] the API version in use ("v2" or "v3")
    attr_reader :api_version

    # @param token [String] the Bayarcash API token
    # @param sandbox [Boolean] use the sandbox environment
    # @param api_version [String] "v2" (default) or "v3"
    # @param timeout [Integer] request timeout in seconds
    def initialize(token, sandbox: false, api_version: "v2", timeout: 30)
      @token = token
      @sandbox = sandbox
      @api_version = api_version
      @timeout = timeout
      build_connection
    end

    # Set the API token and rebuild the HTTP client.
    #
    # @param token [String]
    # @param connection [Faraday::Connection, nil] inject a custom connection (mainly for tests)
    # @return [self]
    def set_token(token, connection = nil)
      @token = token
      connection ? (@connection = connection) : build_connection
      self
    end

    # Switch to the sandbox environment and rebuild the HTTP client.
    #
    # @param connection [Faraday::Connection, nil]
    # @return [self]
    def use_sandbox(connection = nil)
      @sandbox = true
      connection ? (@connection = connection) : build_connection
      self
    end

    # @return [Boolean]
    def sandbox?
      @sandbox
    end

    # Set the request timeout and rebuild the HTTP client.
    #
    # @param timeout [Integer] seconds
    # @return [self]
    def set_timeout(timeout)
      @timeout = timeout
      build_connection
      self
    end

    # @return [Integer]
    def get_timeout
      @timeout
    end

    # Set the API version ("v2" or "v3") and rebuild the HTTP client.
    #
    # @param version [String]
    # @return [self]
    def set_api_version(version)
      @api_version = version
      build_connection
      self
    end

    # @return [String]
    def get_api_version
      @api_version
    end

    # Get the list of FPX banks.
    #
    # @return [Array<Bayarcash::Resources::FpxBankResource>]
    def fpx_banks_list
      transform_collection(get("banks"), Resources::FpxBankResource)
    end

    # Get the list of portals.
    #
    # @return [Array<Bayarcash::Resources::PortalResource>]
    def get_portals
      response = get("portals")
      collection = response.is_a?(Hash) ? (response["data"] || response) : response
      transform_collection(collection, Resources::PortalResource)
    end

    # Get the payment channels available for a portal by portal key.
    #
    # @param portal_key [String]
    # @return [Array]
    def get_channels(portal_key)
      get_portals.each do |portal|
        return portal.payment_channels if portal.portal_key == portal_key
      end
      []
    end

    # Create a new payment intent.
    #
    # @param data [Hash]
    # @return [Bayarcash::Resources::PaymentIntentResource]
    def create_payment_intent(data)
      Resources::PaymentIntentResource.new(post("payment-intents", data), self)
    end

    # Get transaction details (v2 and v3).
    #
    # @param id [String]
    # @return [Bayarcash::Resources::TransactionResource]
    def get_transaction(id)
      Resources::TransactionResource.new(get("transactions/#{id}"), self)
    end

    # Get a payment intent by id (v3 only).
    #
    # @param payment_intent_id [String]
    # @return [Bayarcash::Resources::PaymentIntentResource]
    # @raise [Bayarcash::Error] when the API version is not v3
    def get_payment_intent(payment_intent_id)
      ensure_v3!("getPaymentIntent")
      Resources::PaymentIntentResource.new(get("payment-intents/#{payment_intent_id}"), self)
    end

    # Cancel a payment intent (v3 only).
    #
    # @param payment_intent_id [String]
    # @return [Bayarcash::Resources::PaymentIntentResource]
    # @raise [Bayarcash::Error] when the API version is not v3
    def cancel_payment_intent(payment_intent_id)
      ensure_v3!("cancelPaymentIntent")
      Resources::PaymentIntentResource.new(delete("payment-intents/#{payment_intent_id}"), self)
    end

    # Get all transactions with optional filters (v3 only).
    #
    # @param parameters [Hash] any of :order_number, :status, :payment_channel,
    #   :exchange_reference_number, :payer_email
    # @return [Hash] { data: Array<TransactionResource>, meta: Hash }
    # @raise [Bayarcash::Error] when the API version is not v3
    def get_all_transactions(parameters = {})
      ensure_v3!("getAllTransactions")

      query_params = parameters.select { |key, _| ALLOWED_TRANSACTION_FILTERS.include?(key.to_s) }
      query_string = Bayarcash::Util.build_query(query_params)
      endpoint = "transactions" + (query_string.empty? ? "" : "?#{query_string}")

      response = get(endpoint)

      {
        data: transform_collection(response.is_a?(Hash) ? (response["data"] || []) : [], Resources::TransactionResource),
        meta: response.is_a?(Hash) ? (response["meta"] || {}) : {}
      }
    end

    # Get transactions by order number (v3 only).
    #
    # @param order_number [String]
    # @return [Array<Bayarcash::Resources::TransactionResource>]
    # @raise [Bayarcash::Error] when the API version is not v3
    def get_transaction_by_order_number(order_number)
      ensure_v3!("getTransactionByOrderNumber")
      response = get("transactions?order_number=#{order_number}")
      transform_collection(response.is_a?(Hash) ? (response["data"] || []) : [], Resources::TransactionResource)
    end

    # Get transactions by payer email (v3 only).
    #
    # @param email [String]
    # @return [Array<Bayarcash::Resources::TransactionResource>]
    # @raise [Bayarcash::Error] when the API version is not v3
    def get_transactions_by_payer_email(email)
      ensure_v3!("getTransactionsByPayerEmail")
      response = get("transactions?payer_email=#{Bayarcash::Util.url_encode(email)}")
      transform_collection(response.is_a?(Hash) ? (response["data"] || []) : [], Resources::TransactionResource)
    end

    # Get transactions by status (v3 only).
    #
    # @param status [String]
    # @return [Array<Bayarcash::Resources::TransactionResource>]
    # @raise [Bayarcash::Error] when the API version is not v3
    def get_transactions_by_status(status)
      ensure_v3!("getTransactionsByStatus")
      response = get("transactions?status=#{status}")
      transform_collection(response.is_a?(Hash) ? (response["data"] || []) : [], Resources::TransactionResource)
    end

    # Get transactions by payment channel (v3 only).
    #
    # @param channel [Integer]
    # @return [Array<Bayarcash::Resources::TransactionResource>]
    # @raise [Bayarcash::Error] when the API version is not v3
    def get_transactions_by_payment_channel(channel)
      ensure_v3!("getTransactionsByPaymentChannel")
      response = get("transactions?payment_channel=#{channel}")
      transform_collection(response.is_a?(Hash) ? (response["data"] || []) : [], Resources::TransactionResource)
    end

    # Get a single transaction by exchange reference number (v3 only).
    #
    # @param reference_number [String]
    # @return [Bayarcash::Resources::TransactionResource, nil]
    # @raise [Bayarcash::Error] when the API version is not v3
    def get_transaction_by_reference_number(reference_number)
      ensure_v3!("getTransactionByReferenceNumber")
      response = get("transactions?exchange_reference_number=#{Bayarcash::Util.url_encode(reference_number)}")
      data = response.is_a?(Hash) ? (response["data"] || []) : []
      return nil if data.nil? || data.empty?

      transform_collection(data, Resources::TransactionResource).first
    end

    # Return the base URI for the current API version and environment.
    #
    # @return [String]
    def base_uri
      if @api_version == "v3"
        @sandbox ? "https://api.console.bayarcash-sandbox.com/v3/" : "https://api.console.bayar.cash/v3/"
      else
        @sandbox ? "https://console.bayarcash-sandbox.com/api/v2/" : "https://console.bayar.cash/api/v2/"
      end
    end

    private

    # Transform a raw collection into an array of resources.
    def transform_collection(collection, klass, extra = {})
      (collection || []).map do |data|
        klass.new((data || {}).merge(extra), self)
      end
    end

    def ensure_v3!(method_name)
      return if @api_version == "v3"

      raise Bayarcash::Error, "The #{method_name} method is only available for API version v3."
    end
  end
end
