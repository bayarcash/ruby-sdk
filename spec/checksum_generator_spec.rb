# frozen_string_literal: true

RSpec.describe Bayarcash::ChecksumGenerator do
  let(:secret) { "sk_test_secret" }
  let(:sdk) { Bayarcash::Client.new("test-token") }

  # Reference recipe from the gateway server: sort by key, join values with "|",
  # then HMAC-SHA256 with the merchant secret. Pins the SDK to that contract.
  def expected(fields)
    payload = fields.sort_by { |key, _| key.to_s }.map { |_, value| value.to_s }.join("|")
    OpenSSL::HMAC.hexdigest("SHA256", secret, payload)
  end

  it "payment intent checksum matches the server recipe" do
    data = {
      "payment_channel" => 5,
      "order_number"    => "ORD1",
      "amount"          => "10.00",
      "payer_name"      => "John Doe",
      "payer_email"     => "john@example.com"
    }

    known_vector = expected(
      "payment_channel" => "5",
      "order_number"    => "ORD1",
      "amount"          => "10.00",
      "payer_name"      => "John Doe",
      "payer_email"     => "john@example.com"
    )

    expect(sdk.create_payment_intent_checksum_value(secret, data)).to eq(known_vector)
  end

  it "produces a 64-character lowercase hex digest" do
    data = { "order_number" => "ORD1", "amount" => "10.00", "payer_name" => "John", "payer_email" => "a@b.com" }
    digest = sdk.create_payment_intent_checksum_value(secret, data)

    expect(digest).to match(/\A[0-9a-f]{64}\z/)
  end

  it "treats an int payment_channel and a single-element array as equivalent" do
    base = { "order_number" => "ORD1", "amount" => "10.00", "payer_name" => "John", "payer_email" => "a@b.com" }

    as_int   = sdk.create_payment_intent_checksum_value(secret, base.merge("payment_channel" => 5))
    as_array = sdk.create_payment_intent_checksum_value(secret, base.merge("payment_channel" => [5]))

    expect(as_int).to eq(as_array)
  end

  it "comma-joins multiple payment channels" do
    data = {
      "order_number" => "ORD1", "amount" => "10.00", "payer_name" => "John",
      "payer_email" => "a@b.com", "payment_channel" => [1, 2]
    }

    known_vector = expected(
      "payment_channel" => "1,2",
      "order_number"    => "ORD1",
      "amount"          => "10.00",
      "payer_name"      => "John",
      "payer_email"     => "a@b.com"
    )

    expect(sdk.create_payment_intent_checksum_value(secret, data)).to eq(known_vector)
  end

  it "leaves payment_channel empty when none is provided" do
    data = { "order_number" => "ORD1", "amount" => "10.00", "payer_name" => "John", "payer_email" => "a@b.com" }

    known_vector = expected(
      "payment_channel" => "",
      "order_number"    => "ORD1",
      "amount"          => "10.00",
      "payer_name"      => "John",
      "payer_email"     => "a@b.com"
    )

    expect(sdk.create_payment_intent_checksum_value(secret, data)).to eq(known_vector)
  end

  it "exposes the misspelled alias that matches the correct method" do
    data = { "order_number" => "ORD1", "amount" => "10.00", "payer_name" => "John", "payer_email" => "a@b.com", "payment_channel" => 5 }

    expect(sdk.create_payment_inten_checksum_value(secret, data))
      .to eq(sdk.create_payment_intent_checksum_value(secret, data))
  end

  it "accepts symbol keys" do
    string_keyed = { "order_number" => "ORD1", "amount" => "10.00", "payer_name" => "John", "payer_email" => "a@b.com", "payment_channel" => 5 }
    symbol_keyed = { order_number: "ORD1", amount: "10.00", payer_name: "John", payer_email: "a@b.com", payment_channel: 5 }

    expect(sdk.create_payment_intent_checksum_value(secret, symbol_keyed))
      .to eq(sdk.create_payment_intent_checksum_value(secret, string_keyed))
  end

  it "direct-debit enrolment checksum matches the server recipe" do
    data = {
      "order_number"           => "ORD1",
      "amount"                 => "10.00",
      "payer_name"             => "John Doe",
      "payer_email"            => "john@example.com",
      "payer_telephone_number" => "0123456789",
      "payer_id_type"          => 1,
      "payer_id"               => "900101011234",
      "application_reason"     => "Monthly subscription",
      "frequency_mode"         => "MT"
    }

    expect(sdk.create_fpx_direct_debit_enrolment_checksum_value(secret, data)).to eq(expected(data))
  end

  it "direct-debit maintenance checksum matches the server recipe" do
    data = {
      "amount"                 => "10.00",
      "payer_email"            => "john@example.com",
      "payer_telephone_number" => "0123456789",
      "application_reason"     => "Update amount",
      "frequency_mode"         => "MT"
    }

    expect(sdk.create_fpx_direct_debit_maintenance_checksum_value(secret, data)).to eq(expected(data))
  end
end
