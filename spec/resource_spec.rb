# frozen_string_literal: true

RSpec.describe Bayarcash::Resources::Resource do
  it "fills snake_case keys as reader methods" do
    resource = Bayarcash::Resources::TransactionResource.new(
      "order_number" => "ORDER123",
      "payer_email"  => "customer@example.com"
    )

    expect(resource.order_number).to eq("ORDER123")
    expect(resource.payer_email).to eq("customer@example.com")
  end

  it "returns nil for declared attributes the API omitted, instead of raising" do
    resource = Bayarcash::Resources::PaymentIntentResource.new("order_number" => "ORDER123")

    expect(resource.order_number).to eq("ORDER123")
    expect(resource.url).to be_nil
    expect(resource.amount).to be_nil
    expect(resource.status).to be_nil
  end

  it "captures unknown fields the API returns" do
    resource = Bayarcash::Resources::PortalResource.new(
      "portal_key"                => "abc",
      "brand_new_field_from_api"  => "value"
    )

    expect(resource.portal_key).to eq("abc")
    expect(resource.brand_new_field_from_api).to eq("value")
    expect(resource["brand_new_field_from_api"]).to eq("value")
  end

  it "accepts symbol keys" do
    resource = Bayarcash::Resources::TransactionResource.new(order_number: "ORD9")

    expect(resource.order_number).to eq("ORD9")
  end

  it "converts to a hash excluding the client instance" do
    client = Bayarcash::Client.new("token")
    resource = Bayarcash::Resources::TransactionResource.new({ "id" => "trx_1", "amount" => 10.5 }, client)

    array = resource.to_h

    expect(array).not_to have_key("bayarcash")
    expect(array["id"]).to eq("trx_1")
    expect(array["amount"]).to eq(10.5)
  end

  it "deeply converts nested resources in to_h" do
    child = Bayarcash::Resources::TransactionResource.new("id" => "child")
    parent = Bayarcash::Resources::PortalResource.new("id" => "parent", "merchant" => [child])

    expect(parent.to_h["merchant"]).to eq([{ "id" => "child" }])
  end
end
