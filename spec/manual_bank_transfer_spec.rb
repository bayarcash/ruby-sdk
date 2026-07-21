# frozen_string_literal: true

require "tempfile"

RSpec.describe Bayarcash::ManualBankTransfer do
  let(:sdk) { Bayarcash::Client.new("test-token") }
  let(:base) { "https://console.bayar.cash/api" }

  let(:valid_data) do
    {
      "portal_key"                   => "portal_key",
      "buyer_name"                   => "Ahmad bin Abdullah",
      "buyer_email"                  => "ahmad@example.com",
      "order_amount"                 => "10.00",
      "order_no"                     => "MT-1001",
      "payment_gateway"              => 2,
      "merchant_bank_name"           => "Maybank",
      "merchant_bank_account"        => "1234567890",
      "merchant_bank_account_holder" => "Company Sdn Bhd",
      "bank_transfer_type"           => "Internet Banking",
      "bank_transfer_notes"          => "Payment for MT-1001"
    }
  end

  describe "validation" do
    it "raises when a required field is missing" do
      valid_data.delete("portal_key")

      expect { sdk.create_manual_bank_transfer(valid_data) }
        .to raise_error(ArgumentError, /portal_key/)
    end

    it "raises when payment_gateway is not 2" do
      expect { sdk.create_manual_bank_transfer(valid_data.merge("payment_gateway" => 1)) }
        .to raise_error(ArgumentError, /Value must be 2/)
    end

    it "raises when the proof_of_payment file does not exist" do
      expect { sdk.create_manual_bank_transfer(valid_data.merge("proof_of_payment" => "/no/such/file.jpg")) }
        .to raise_error(ArgumentError, /Proof of payment file does not exist/)
    end
  end

  describe "#create_manual_bank_transfer" do
    it "returns the decoded JSON body on success" do
      stub_request(:post, "#{base}/manual-bank-transfer")
        .to_return(status: 200, body: { "success" => true, "reference" => "MT-1001" }.to_json)

      response = sdk.create_manual_bank_transfer(valid_data)

      expect(response).to eq("success" => true, "reference" => "MT-1001")
    end

    it "parses an HTML form response" do
      html = <<~HTML
        <form id="paymentForm" action="https://gateway.example/redirect">
          <input name="order_no" type="hidden" value="MT-1001">
          <input name="amount" type="hidden" value="10.00">
        </form>
      HTML

      stub_request(:post, "#{base}/manual-bank-transfer").to_return(status: 200, body: html)

      response = sdk.create_manual_bank_transfer(valid_data)

      expect(response[:success]).to be(true)
      expect(response[:return_url]).to eq("https://gateway.example/redirect")
      expect(response[:form_data]["order_no"]).to eq("MT-1001")
      expect(response[:form_data]["amount"]).to eq("10.00")
    end

    it "uploads a proof_of_payment file as multipart" do
      file = Tempfile.new(["receipt", ".png"])
      file.write("fake-image-bytes")
      file.rewind

      stub = stub_request(:post, "#{base}/manual-bank-transfer")
             .with(headers: { "Content-Type" => %r{multipart/form-data} })
             .to_return(status: 200, body: { "success" => true }.to_json)

      sdk.create_manual_bank_transfer(valid_data.merge("proof_of_payment" => file.path))

      expect(stub).to have_been_requested
    ensure
      file.close
      file.unlink
    end

    it "raises a Bayarcash::Error with the API message on failure" do
      stub_request(:post, "#{base}/manual-bank-transfer")
        .to_return(status: 422, body: { "message" => "Validation failed" }.to_json)

      expect { sdk.create_manual_bank_transfer(valid_data) }
        .to raise_error(Bayarcash::Error, "Validation failed")
    end
  end

  describe "#update_manual_bank_transfer_status" do
    it "posts a form-encoded status update" do
      stub = stub_request(:post, "#{base}/manual-bank-transfer/update-status")
             .with(
               body: { "ref_no" => "REF1", "status" => "3", "amount" => "10.00" },
               headers: { "Content-Type" => "application/x-www-form-urlencoded" }
             )
             .to_return(status: 200, body: { "updated" => true }.to_json)

      response = sdk.update_manual_bank_transfer_status("REF1", "3", "10.00")

      expect(stub).to have_been_requested
      expect(response).to eq("updated" => true)
    end
  end
end
