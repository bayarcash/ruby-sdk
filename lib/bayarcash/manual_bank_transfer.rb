# frozen_string_literal: true

module Bayarcash
  # Manual (offline) bank transfer operations.
  #
  # These calls hit a different base URL than the versioned API (no /v2 or /v3
  # segment) and support a multipart `proof_of_payment` file upload.
  module ManualBankTransfer
    REQUIRED_MANUAL_TRANSFER_FIELDS = %w[
      portal_key buyer_name buyer_email order_amount order_no payment_gateway
      merchant_bank_name merchant_bank_account merchant_bank_account_holder
      bank_transfer_type bank_transfer_notes
    ].freeze

    FILE_CONTENT_TYPES = {
      "jpg"  => "image/jpeg",
      "jpeg" => "image/jpeg",
      "png"  => "image/png",
      "gif"  => "image/gif",
      "pdf"  => "application/pdf"
    }.freeze

    # Create a manual bank transfer payment.
    #
    # @param data [Hash] payment and customer details (see README for the field list)
    # @param allow_redirect [Boolean] whether to auto-follow HTTP redirects
    # @return [Hash, String] response hash or raw string depending on the API response
    # @raise [ArgumentError] when required fields are missing or invalid
    # @raise [Bayarcash::Error] when the API request fails
    def create_manual_bank_transfer(data, allow_redirect = false)
      data = stringify_keys(data)

      validate_manual_transfer_data(data)

      data["bank_transfer_date"] ||= Date.today.strftime("%Y-%m-%d")

      post_fields = prepare_manual_transfer_post_fields(data)

      response = execute_manual_transfer_request(post_fields, allow_redirect)

      process_manual_transfer_response(response[:body], response[:http_code], allow_redirect)
    end

    # Update the status of an existing manual bank transfer.
    #
    # @param ref_no [String] transaction reference number
    # @param status [String] new status code
    # @param amount [String] transaction amount
    # @return [Object] decoded API response
    # @raise [Bayarcash::Error] when the update fails
    def update_manual_bank_transfer_status(ref_no, status, amount)
      data = { "ref_no" => ref_no, "status" => status, "amount" => amount }

      conn = Faraday.new do |faraday|
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
      end

      url = "#{manual_transfer_base_url}/manual-bank-transfer/update-status"

      begin
        response = conn.post(url) do |req|
          req.headers["Accept"] = "application/json"
          req.headers["Authorization"] = "Bearer #{@token}"
          req.headers["Content-Type"] = "application/x-www-form-urlencoded"
          req.body = data
        end
      rescue Faraday::Error => e
        raise Bayarcash::Error, "Connection failed: #{e.message}"
      end

      handle_api_response(response.body.to_s, response.status)
    end

    # Extract structured data from an HTML form response.
    #
    # @param html_response [String]
    # @return [Hash{String => String}]
    def parse_manual_bank_transfer_response(html_response)
      data = {}

      if (form_id = html_response[/id="([^"]+)"/, 1])
        data["form_id"] = form_id
      end

      if (return_url = html_response[/action="([^"]+)"/, 1])
        data["return_url"] = return_url
      end

      html_response.scan(/<input name="([^"]+)" type="hidden" value="([^"]*)">/).each do |name, value|
        data[name] = value
      end

      data
    end

    protected

    # The manual-transfer base URL (note: no /v2 or /v3 segment).
    #
    # @return [String]
    def manual_transfer_base_url
      @sandbox ? "https://console.bayarcash-sandbox.com/api" : "https://console.bayar.cash/api"
    end

    private

    def validate_manual_transfer_data(data)
      REQUIRED_MANUAL_TRANSFER_FIELDS.each do |field|
        if data[field].nil?
          raise ArgumentError, "Required field '#{field}' is missing"
        end
      end

      if data["payment_gateway"].nil? || data["payment_gateway"].to_s != "2"
        raise ArgumentError, "Invalid payment gateway. Value must be 2 for manual bank transfers."
      end

      if data["proof_of_payment"] && !File.exist?(data["proof_of_payment"])
        raise ArgumentError, "Proof of payment file does not exist"
      end
    end

    def prepare_manual_transfer_post_fields(data)
      post_fields = {}

      data.each do |key, value|
        post_fields[key] = value unless key == "proof_of_payment"
      end

      if data["proof_of_payment"] && File.exist?(data["proof_of_payment"])
        path = data["proof_of_payment"]
        post_fields["proof_of_payment"] = Faraday::Multipart::FilePart.new(
          path,
          file_content_type(path),
          File.basename(path)
        )
      end

      post_fields
    end

    def execute_manual_transfer_request(post_fields, allow_redirect)
      conn = Faraday.new do |faraday|
        faraday.request :multipart
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
      end

      url = "#{manual_transfer_base_url}/manual-bank-transfer"

      begin
        response = conn.post(url) do |req|
          req.headers["Accept"] = "application/json"
          req.headers["Authorization"] = "Bearer #{@token}"
          req.body = post_fields
        end

        redirects = 0
        while allow_redirect && response.status >= 300 && response.status < 400 &&
              response.headers["location"] && redirects < 10
          response = Faraday.get(response.headers["location"])
          redirects += 1
        end
      rescue Faraday::Error => e
        raise Bayarcash::Error, "cURL Error: #{e.message}"
      end

      { body: response.body.to_s, http_code: response.status }
    end

    def process_manual_transfer_response(response, http_code, allow_redirect)
      if http_code >= 200 && http_code < 300
        if response.include?("<form")
          parsed = parse_manual_bank_transfer_response(response)

          {
            success: true,
            html_form: response,
            form_data: parsed,
            return_url: parsed["return_url"]
          }
        else
          decoded = Bayarcash::Util.safe_json(response)
          decoded && !Bayarcash::Util.php_falsy?(decoded) ? decoded : response
        end
      elsif http_code >= 300 && http_code < 400 && !allow_redirect
        { redirect_url: response }
      else
        handle_api_error(response, http_code)
      end
    end

    def handle_api_error(response, http_code)
      decoded = Bayarcash::Util.safe_json(response)

      if decoded.is_a?(Hash) && decoded.key?("message")
        raise Bayarcash::Error, decoded["message"]
      else
        raise Bayarcash::Error, "API Error (HTTP #{http_code}): #{response[0, 200]}"
      end
    end

    def handle_api_response(response, http_code)
      if http_code >= 200 && http_code < 300
        decoded = Bayarcash::Util.safe_json(response)
        decoded && !Bayarcash::Util.php_falsy?(decoded) ? decoded : response
      else
        handle_api_error(response, http_code)
      end
    end

    def file_content_type(file_path)
      extension = File.extname(file_path).delete(".").downcase
      FILE_CONTENT_TYPES.fetch(extension, "application/octet-stream")
    end

    def stringify_keys(data)
      (data || {}).each_with_object({}) do |(key, value), memo|
        memo[key.to_s] = value
      end
    end
  end
end
