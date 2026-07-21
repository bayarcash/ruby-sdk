# frozen_string_literal: true

RSpec.describe Bayarcash::MakesHttpRequests do
  let(:sdk) { Bayarcash::Client.new("test-token") }
  let(:base) { "https://console.bayar.cash/api/v2" }

  it "decodes a successful JSON response to a hash" do
    stub_request(:get, "#{base}/anything").to_return(status: 200, body: { "foo" => "bar" }.to_json)

    expect(sdk.get("anything")).to eq("foo" => "bar")
  end

  it "returns the raw body when the response is not JSON" do
    stub_request(:get, "#{base}/anything").to_return(status: 200, body: "plain body")

    expect(sdk.get("anything")).to eq("plain body")
  end

  it "raises ValidationError with the errors payload on 422" do
    stub_request(:get, "#{base}/anything")
      .to_return(status: 422, body: { "error" => { "amount" => ["The amount field is required."] } }.to_json)

    expect { sdk.get("anything") }.to raise_error(Bayarcash::ValidationError) do |error|
      expect(error.errors).to have_key("error")
    end
  end

  it "raises NotFoundError on 404" do
    stub_request(:get, "#{base}/anything").to_return(status: 404, body: "")

    expect { sdk.get("anything") }.to raise_error(Bayarcash::NotFoundError)
  end

  it "raises FailedActionError with the message on 400" do
    stub_request(:get, "#{base}/anything").to_return(status: 400, body: { "message" => "Bad request happened" }.to_json)

    expect { sdk.get("anything") }.to raise_error(Bayarcash::FailedActionError, "Bad request happened")
  end

  it "extracts the error key on a 400 when there is no message" do
    stub_request(:get, "#{base}/anything").to_return(status: 400, body: { "error" => "Something went wrong" }.to_json)

    expect { sdk.get("anything") }.to raise_error(Bayarcash::FailedActionError, "Something went wrong")
  end

  it "still raises FailedActionError for a non-JSON 400 body" do
    stub_request(:get, "#{base}/anything").to_return(status: 400, body: "plain text error")

    expect { sdk.get("anything") }.to raise_error(Bayarcash::FailedActionError, "plain text error")
  end

  it "raises RateLimitExceededError with the reset timestamp on 429" do
    stub_request(:get, "#{base}/anything")
      .to_return(status: 429, headers: { "x-ratelimit-reset" => "1700000000" }, body: "")

    expect { sdk.get("anything") }.to raise_error(Bayarcash::RateLimitExceededError) do |error|
      expect(error.rate_limit_resets_at).to eq(1_700_000_000)
    end
  end

  it "raises the generic Error on other non-2xx statuses" do
    stub_request(:get, "#{base}/anything").to_return(status: 500, body: "server exploded")

    expect { sdk.get("anything") }.to raise_error(Bayarcash::Error, "server exploded")
  end

  it "sends a POST body as form-urlencoded by default" do
    stub = stub_request(:post, "#{base}/payment-intents")
           .with(headers: { "Content-Type" => "application/x-www-form-urlencoded" }, body: "amount=10.00&order_number=INV-1")
           .to_return(status: 200, body: { "url" => "https://pay" }.to_json)

    sdk.post("payment-intents", { "amount" => "10.00", "order_number" => "INV-1" })

    expect(stub).to have_been_requested
  end

  it "sends a JSON body when the payload is wrapped in :json" do
    stub = stub_request(:post, "#{base}/payment-intents")
           .with(headers: { "Content-Type" => "application/json" }, body: { "amount" => "10.00" }.to_json)
           .to_return(status: 200, body: "{}")

    sdk.post("payment-intents", { json: { "amount" => "10.00" } })

    expect(stub).to have_been_requested
  end

  it "defaults the API version to v2 and reflects the setter" do
    expect(sdk.get_api_version).to eq("v2")

    sdk.set_api_version("v3")
    expect(sdk.get_api_version).to eq("v3")
  end

  it "raises when a v3-only method is called on v2" do
    expect { sdk.get_all_transactions }.to raise_error(Bayarcash::Error)
  end
end
