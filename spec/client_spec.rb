# frozen_string_literal: true

RSpec.describe Bayarcash::Client do
  let(:sdk) { Bayarcash::Client.new("test-token") }

  describe "base URI selection" do
    it "uses the v2 production URI by default" do
      expect(sdk.base_uri).to eq("https://console.bayar.cash/api/v2/")
    end

    it "uses the v2 sandbox URI in sandbox mode" do
      sdk.use_sandbox
      expect(sdk.base_uri).to eq("https://console.bayarcash-sandbox.com/api/v2/")
    end

    it "uses the v3 production URI" do
      sdk.set_api_version("v3")
      expect(sdk.base_uri).to eq("https://api.console.bayar.cash/v3/")
    end

    it "uses the v3 sandbox URI" do
      sdk.use_sandbox.set_api_version("v3")
      expect(sdk.base_uri).to eq("https://api.console.bayarcash-sandbox.com/v3/")
    end
  end

  describe "payment channel constants" do
    it "defines all 21 channels including the gap at 20" do
      expect(described_class::FPX).to eq(1)
      expect(described_class::GRABPL).to eq(19)
      expect(described_class::SHOPEE_PAY).to eq(21)
      expect(described_class.constants).not_to include(:CHANNEL_20)
    end
  end

  describe "#fpx_banks_list" do
    it "returns FpxBankResource objects" do
      stub_request(:get, "https://console.bayar.cash/api/v2/banks")
        .to_return(status: 200, body: [{ "bank_name" => "Maybank", "bank_code" => "MBB0228" }].to_json)

      banks = sdk.fpx_banks_list

      expect(banks.length).to eq(1)
      expect(banks.first).to be_a(Bayarcash::Resources::FpxBankResource)
      expect(banks.first.bank_name).to eq("Maybank")
    end
  end

  describe "#get_portals and #get_channels" do
    before do
      stub_request(:get, "https://console.bayar.cash/api/v2/portals")
        .to_return(status: 200, body: {
          "data" => [
            { "portal_key" => "portal_a", "payment_channels" => [{ "id" => 1 }, { "id" => 5 }] },
            { "portal_key" => "portal_b", "payment_channels" => [{ "id" => 2 }] }
          ]
        }.to_json)
    end

    it "returns portal resources" do
      portals = sdk.get_portals
      expect(portals.map(&:portal_key)).to eq(%w[portal_a portal_b])
    end

    it "returns the channels for a matching portal key" do
      expect(sdk.get_channels("portal_a")).to eq([{ "id" => 1 }, { "id" => 5 }])
    end

    it "returns an empty array when no portal matches" do
      expect(sdk.get_channels("missing")).to eq([])
    end
  end

  describe "#get_transaction" do
    it "returns a TransactionResource" do
      stub_request(:get, "https://console.bayar.cash/api/v2/transactions/trx_1")
        .to_return(status: 200, body: { "id" => "trx_1", "status" => "3", "order_number" => "ORD1" }.to_json)

      transaction = sdk.get_transaction("trx_1")

      expect(transaction).to be_a(Bayarcash::Resources::TransactionResource)
      expect(transaction.id).to eq("trx_1")
      expect(transaction.order_number).to eq("ORD1")
    end
  end

  describe "#create_payment_intent" do
    it "posts and returns a PaymentIntentResource" do
      stub_request(:post, "https://console.bayar.cash/api/v2/payment-intents")
        .to_return(status: 200, body: { "url" => "https://pay.example/abc", "id" => "pi_1" }.to_json)

      intent = sdk.create_payment_intent("order_number" => "INV-1", "amount" => "10.00")

      expect(intent).to be_a(Bayarcash::Resources::PaymentIntentResource)
      expect(intent.url).to eq("https://pay.example/abc")
    end
  end

  describe "v3 transaction queries" do
    before { sdk.set_api_version("v3") }

    it "returns data and meta from get_all_transactions" do
      stub_request(:get, "https://api.console.bayar.cash/v3/transactions?status=3")
        .to_return(status: 200, body: { "data" => [{ "id" => "trx_1" }], "meta" => { "total" => 1 } }.to_json)

      result = sdk.get_all_transactions(status: "3", not_allowed: "ignored")

      expect(result[:data].first.id).to eq("trx_1")
      expect(result[:meta]).to eq("total" => 1)
    end

    it "looks up a single transaction by reference number" do
      stub_request(:get, "https://api.console.bayar.cash/v3/transactions?exchange_reference_number=REF123")
        .to_return(status: 200, body: { "data" => [{ "id" => "trx_9" }] }.to_json)

      transaction = sdk.get_transaction_by_reference_number("REF123")
      expect(transaction.id).to eq("trx_9")
    end

    it "returns nil when a reference lookup has no data" do
      stub_request(:get, "https://api.console.bayar.cash/v3/transactions?exchange_reference_number=NONE")
        .to_return(status: 200, body: { "data" => [] }.to_json)

      expect(sdk.get_transaction_by_reference_number("NONE")).to be_nil
    end

    it "cancels a payment intent via DELETE" do
      stub_request(:delete, "https://api.console.bayar.cash/v3/payment-intents/pi_1")
        .to_return(status: 200, body: { "id" => "pi_1", "status" => "cancelled" }.to_json)

      intent = sdk.cancel_payment_intent("pi_1")
      expect(intent.status).to eq("cancelled")
    end
  end

  describe "v3-only guards" do
    it "raises on v2 for get_payment_intent" do
      expect { sdk.get_payment_intent("pi_1") }.to raise_error(Bayarcash::Error, /v3/)
    end

    it "raises on v2 for get_transaction_by_order_number" do
      expect { sdk.get_transaction_by_order_number("INV-1") }.to raise_error(Bayarcash::Error, /v3/)
    end
  end
end
