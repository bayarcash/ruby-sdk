# frozen_string_literal: true

RSpec.describe Bayarcash::CallbackVerifications do
  let(:secret) { "sk_test_secret" }
  let(:sdk) { Bayarcash::Client.new("test-token") }

  # Sign exactly the fields a verifier checks, using the SDK's own generic
  # checksum primitive (same recipe the server uses).
  def sign(fields)
    sdk.create_checksum_value(secret, fields)
  end

  it "round-trips a pre-transaction callback and rejects tampering" do
    fields = {
      "record_type"               => "pre_transaction",
      "exchange_reference_number" => "REF1",
      "order_number"              => "ORD1"
    }
    callback = fields.merge("checksum" => sign(fields))

    expect(sdk.verify_pre_transaction_callback_data(callback, secret)).to be(true)

    callback["order_number"] = "TAMPERED"
    expect(sdk.verify_pre_transaction_callback_data(callback, secret)).to be(false)
  end

  it "round-trips a transaction callback and rejects an altered amount" do
    fields = {
      "record_type"               => "transaction",
      "transaction_id"            => "trx_1",
      "exchange_reference_number" => "REF1",
      "exchange_transaction_id"   => "EX1",
      "order_number"              => "ORD1",
      "currency"                  => "MYR",
      "amount"                    => "10.00",
      "payer_name"                => "John Doe",
      "payer_email"               => "john@example.com",
      "payer_bank_name"           => "Test Bank",
      "status"                    => "3",
      "status_description"        => "Approved",
      "datetime"                  => "2026-01-01 12:00:00"
    }
    callback = fields.merge("checksum" => sign(fields))

    expect(sdk.verify_transaction_callback_data(callback, secret)).to be(true)

    callback["amount"] = "99.00"
    expect(sdk.verify_transaction_callback_data(callback, secret)).to be(false)
  end

  it "round-trips a return-url (v3) callback" do
    fields = {
      "transaction_id"            => "trx_1",
      "exchange_reference_number" => "REF1",
      "exchange_transaction_id"   => "EX1",
      "order_number"              => "ORD1",
      "currency"                  => "MYR",
      "amount"                    => "10.00",
      "payer_bank_name"           => "Test Bank",
      "status"                    => "3",
      "status_description"        => "Approved"
    }
    callback = fields.merge("checksum" => sign(fields))

    expect(sdk.verify_return_url_callback_data(callback, secret)).to be(true)
  end

  it "round-trips a direct-debit bank-approval callback" do
    fields = {
      "record_type"              => "bank_approval",
      "approval_date"            => "2026-01-01",
      "approval_status"          => "approved",
      "mandate_id"               => "mdt_1",
      "mandate_reference_number" => "MREF1",
      "order_number"             => "ORD1",
      "payer_bank_code_hashed"   => "hashed",
      "payer_bank_code"          => "ABB0233",
      "payer_bank_account_no"    => "****1234",
      "application_type"         => "01"
    }
    callback = fields.merge("checksum" => sign(fields))

    expect(sdk.verify_direct_debit_bank_approval_callback_data(callback, secret)).to be(true)
  end

  it "round-trips a direct-debit transaction callback" do
    fields = {
      "record_type"              => "dd_transaction",
      "batch_number"             => "B1",
      "mandate_id"               => "mdt_1",
      "mandate_reference_number" => "MREF1",
      "transaction_id"           => "trx_1",
      "datetime"                 => "2026-01-01 12:00:00",
      "reference_number"         => "REF1",
      "amount"                   => "10.00",
      "status"                   => "3",
      "status_description"       => "Approved",
      "cycle"                    => "1"
    }
    callback = fields.merge("checksum" => sign(fields))

    expect(sdk.verify_direct_debit_transaction_callback_data(callback, secret)).to be(true)
  end

  # The authorization checksum MUST include application_type, which the server
  # signs. Omitting it makes every genuine authorization callback fail.
  it "includes application_type in the direct-debit authorization checksum" do
    fields = {
      "record_type"               => "authorization",
      "transaction_id"            => "trx_1",
      "mandate_id"                => "mdt_1",
      "application_type"          => "01",
      "exchange_reference_number" => "REF1",
      "exchange_transaction_id"   => "EX1",
      "order_number"              => "ORD1",
      "currency"                  => "MYR",
      "amount"                    => "10.00",
      "payer_name"                => "John Doe",
      "payer_email"               => "john@example.com",
      "payer_bank_name"           => "Test Bank",
      "status"                    => "3",
      "status_description"        => "Approved",
      "datetime"                  => "2026-01-01 12:00:00"
    }
    callback = fields.merge("checksum" => sign(fields))

    expect(sdk.verify_direct_debit_authorization_callback_data(callback, secret)).to be(true)

    without_app_type = callback.dup
    without_app_type.delete("application_type")
    expect(sdk.verify_direct_debit_authorization_callback_data(without_app_type, secret)).to be(false)
  end

  it "returns false (without error) when the checksum is missing" do
    expect(sdk.verify_pre_transaction_callback_data(
             { "record_type" => "pre_transaction", "order_number" => "ORD1" }, secret
           )).to be(false)
  end

  it "verifies callbacks supplied with symbol keys" do
    fields = {
      "record_type"               => "pre_transaction",
      "exchange_reference_number" => "REF1",
      "order_number"              => "ORD1"
    }
    callback = { record_type: "pre_transaction", exchange_reference_number: "REF1", order_number: "ORD1", checksum: sign(fields) }

    expect(sdk.verify_pre_transaction_callback_data(callback, secret)).to be(true)
  end
end
