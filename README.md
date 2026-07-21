# Bayarcash Payment Gateway Ruby SDK

[![Gem Version](https://img.shields.io/gem/v/bayarcash.svg)](https://rubygems.org/gems/bayarcash)
[![Gem Downloads](https://img.shields.io/gem/dt/bayarcash.svg)](https://rubygems.org/gems/bayarcash)
[![License](https://img.shields.io/github/license/bayarcash/ruby-sdk.svg)](LICENSE)

The [Bayarcash](https://bayarcash.com/) Ruby SDK provides an expressive, framework-agnostic
interface for interacting with Bayarcash's Payment Gateway API. It is an idiomatic Ruby port
of the official PHP SDK and supports both API **v2** (default) and **v3**, with additional
query features available in v3.

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Getting Started](#getting-started)
  - [Configuration](#configuration)
- [Quick Start: Accept a Payment](#quick-start-accept-a-payment)
- [Payment Channels](#payment-channels)
- [Creating a Payment Intent](#creating-a-payment-intent)
- [Handling Callbacks](#handling-callbacks)
- [Payment & Transaction Status](#payment--transaction-status)
- [Transactions](#transactions)
- [FPX Direct Debit](#fpx-direct-debit)
- [Manual Bank Transfer](#manual-bank-transfer)
- [Portals & FPX Banks](#portals--fpx-banks)
- [Error Handling](#error-handling)
- [Response Objects](#response-objects)
- [Security Recommendations](#security-recommendations)
- [Development](#development)
- [Support](#support)

## Requirements

- Ruby >= 2.7
- [Faraday](https://github.com/lostisland/faraday) 1.10+ / 2.x (installed automatically)
- `faraday-multipart` (installed automatically, used for the manual-transfer file upload)

## Installation

Add to your `Gemfile`:

```ruby
gem "bayarcash"
```

Then run:

```bash
bundle install
```

Or install it directly:

```bash
gem install bayarcash
```

You will need two credentials from your Bayarcash console:

- **API token** — used to authenticate SDK requests.
- **API secret key** — used to generate request checksums and verify callbacks.

## Getting Started

```ruby
require "bayarcash"

bayarcash = Bayarcash::Client.new("YOUR_API_TOKEN")
bayarcash.use_sandbox # remove this line in production
```

The client is a plain object — use it from any framework (Rails, Sinatra, Hanami, a plain
script, …). Nothing global is configured.

### Configuration

```ruby
bayarcash
  .use_sandbox          # switch to the sandbox environment
  .set_api_version("v3") # "v2" (default) or "v3"
  .set_timeout(60)       # request timeout in seconds (default 30)

bayarcash.get_api_version # => "v3"
```

You can also configure everything on construction:

```ruby
bayarcash = Bayarcash::Client.new(
  "YOUR_API_TOKEN",
  sandbox: true,
  api_version: "v3",
  timeout: 60
)
```

> Call `use_sandbox` / `set_api_version` **before** making requests. Omit `use_sandbox` in
> production to hit the live gateway.

## Quick Start: Accept a Payment

A complete FPX payment flow, from creating the payment to verifying the result:

```ruby
require "bayarcash"

bayarcash = Bayarcash::Client.new("YOUR_API_TOKEN")
bayarcash.use_sandbox

api_secret_key = "YOUR_API_SECRET_KEY"

# 1. Build the payment request
data = {
  "portal_key"             => "your_portal_key",
  "payment_channel"        => Bayarcash::Client::FPX,
  "order_number"           => "INV-1001",
  "amount"                 => "10.00",
  "payer_name"             => "Ahmad bin Abdullah",
  "payer_email"            => "ahmad@example.com",
  "payer_telephone_number" => "0123456789",
  "return_url"             => "https://your-site.com/payment/return",
  "callback_url"           => "https://your-site.com/payment/callback"
}

# 2. Sign it (recommended)
data["checksum"] = bayarcash.create_payment_intent_checksum_value(api_secret_key, data)

# 3. Create the payment intent and redirect the payer to Bayarcash
payment_intent = bayarcash.create_payment_intent(data)

redirect_to payment_intent.url # or: response.headers["Location"] = payment_intent.url
```

After payment, Bayarcash calls your `callback_url` (server-to-server) and redirects the payer
to your `return_url`. Verify both — see [Handling Callbacks](#handling-callbacks).

## Payment Channels

Pass one of these constants (or an array of them) as `payment_channel`:

```ruby
Bayarcash::Client::FPX                # FPX Online Banking      (1)
Bayarcash::Client::MANUAL_TRANSFER    # Manual Bank Transfer    (2)
Bayarcash::Client::FPX_DIRECT_DEBIT   # FPX Direct Debit        (3)
Bayarcash::Client::FPX_LINE_OF_CREDIT # FPX Line of Credit      (4)
Bayarcash::Client::DUITNOW_DOBW       # DuitNow Online Banking  (5)
Bayarcash::Client::DUITNOW_QR         # DuitNow QR              (6)
Bayarcash::Client::SPAYLATER          # ShopeePayLater          (7)
Bayarcash::Client::BOOST_PAYFLEX      # Boost PayFlex           (8)
Bayarcash::Client::QRISOB             # QRIS Online Banking     (9)
Bayarcash::Client::QRISWALLET         # QRIS Wallet             (10)
Bayarcash::Client::NETS               # NETS                    (11)
Bayarcash::Client::CREDIT_CARD        # Credit Card             (12)
Bayarcash::Client::ALIPAY             # Alipay                  (13)
Bayarcash::Client::WECHATPAY          # WeChat Pay              (14)
Bayarcash::Client::PROMPTPAY          # PromptPay               (15)
Bayarcash::Client::TOUCH_N_GO         # Touch 'n Go eWallet     (16)
Bayarcash::Client::BOOST_WALLET       # Boost Wallet            (17)
Bayarcash::Client::GRABPAY            # GrabPay                 (18)
Bayarcash::Client::GRABPL             # Grab PayLater           (19)
Bayarcash::Client::SHOPEE_PAY         # ShopeePay               (21)
```

> Note there is intentionally no channel id `20` — `SHOPEE_PAY` is `21`.

## Creating a Payment Intent

```ruby
payment_intent = bayarcash.create_payment_intent(data)
```

**Request fields:**

| Field | Required | Description |
|---|---|---|
| `portal_key` | ✅ | Your portal key. |
| `order_number` | ✅ | Your reference. Max 30 chars. |
| `amount` | ✅ | String with up to 2 decimals, e.g. `"10.00"`. Range `1.00`–`30000.00` (min differs for some channels). |
| `payer_name` | ✅ | Max 150 chars. |
| `payer_email` | ✅ | Valid email, max 250 chars. |
| `payment_channel` | ➖ | A `Bayarcash::Client::*` channel id, or an array of ids. If omitted, the payer chooses on the Bayarcash page. |
| `payer_telephone_number` | ➖ | Required for e-wallet / DuitNow channels. Max 20 chars. |
| `return_url` | ➖ | Where the payer's browser is redirected after payment. |
| `callback_url` | ➖ | Server-to-server notification URL. |
| `metadata` | ➖ | Any extra data you want echoed back. |
| `checksum` | ➖ | Recommended. See below. |

### Checksum

The checksum protects the request from tampering. Generate it **after** building the request
and append it as `checksum`:

```ruby
data["checksum"] = bayarcash.create_payment_intent_checksum_value(api_secret_key, data)
```

The checksum is computed from `payment_channel`, `order_number`, `amount`, `payer_name`, and
`payer_email` (sorted by key, values joined with `|`, then HMAC-SHA256 with your secret key).

## Handling Callbacks

Bayarcash sends **two kinds** of notification. Always verify them with your API secret key
before trusting the data.

| Notification | How it arrives | Read it from |
|---|---|---|
| `callback_url` (transaction) | Server-to-server **POST** (form-encoded) | `request.POST` / `params` |
| `return_url` (payer redirect) | Browser redirect — **POST** on v2, **GET** query on v3 | `params` |

```ruby
callback_data = params.to_unsafe_h # Rails; or any Hash of the callback params

# Transaction callback (sent to your callback_url)
if bayarcash.verify_transaction_callback_data(callback_data, api_secret_key)
  # Data is authentic — safe to process.
end

# Payer redirect (sent to your return_url)
if bayarcash.verify_return_url_callback_data(callback_data, api_secret_key)
  # ...
end

# Pre-transaction callback (sent before the transaction record)
if bayarcash.verify_pre_transaction_callback_data(callback_data, api_secret_key)
  # ...
end
```

Each verifier returns `true` only when the checksum matches, using a **constant-time
comparison** to resist timing attacks. Callback keys may be strings or symbols. See
[FPX Direct Debit](#fpx-direct-debit) for mandate-specific callback verifiers.

## Payment & Transaction Status

Transaction status is an integer code. Use the `Fpx` helper instead of hardcoding numbers:

```ruby
Bayarcash::Fpx::STATUS_NEW       # 0
Bayarcash::Fpx::STATUS_PENDING   # 1
Bayarcash::Fpx::STATUS_FAILED    # 2
Bayarcash::Fpx::STATUS_SUCCESS   # 3
Bayarcash::Fpx::STATUS_CANCELLED # 4

if callback_data["status"].to_i == Bayarcash::Fpx::STATUS_SUCCESS
  # Payment successful
end

Bayarcash::Fpx.get_status_text(callback_data["status"].to_i) # e.g. "Successful"
```

DuitNow (DOBW) statuses live on `Bayarcash::DuitNow::Dobw`, and mandate statuses on
`Bayarcash::FpxDirectDebit`.

## Transactions

```ruby
# Get a single transaction (v2 and v3)
transaction = bayarcash.get_transaction("transaction_id")
```

The following query helpers require **API v3** and raise on v2:

```ruby
bayarcash.set_api_version("v3")

result = bayarcash.get_all_transactions(
  order_number:              "INV-1001",
  status:                    "3",
  payment_channel:           Bayarcash::Client::FPX,
  exchange_reference_number: "REF123",
  payer_email:               "ahmad@example.com"
)
# result[:data] => Array<TransactionResource>, result[:meta] => pagination meta

by_order   = bayarcash.get_transaction_by_order_number("INV-1001")
by_email   = bayarcash.get_transactions_by_payer_email("ahmad@example.com")
by_status  = bayarcash.get_transactions_by_status("3")
by_channel = bayarcash.get_transactions_by_payment_channel(Bayarcash::Client::FPX)
by_ref     = bayarcash.get_transaction_by_reference_number("REF123") # single or nil

# Get a payment intent by id (v3 only)
intent = bayarcash.get_payment_intent("payment_intent_id")

# Cancel a payment intent (v3 only)
bayarcash.cancel_payment_intent("payment_intent_id")
```

## FPX Direct Debit

FPX Direct Debit lets you set up a recurring mandate and later maintain or terminate it.
Constants live on the `FpxDirectDebit` class:

```ruby
# Payer ID type
Bayarcash::FpxDirectDebit::NRIC                  # 1 (New IC)
Bayarcash::FpxDirectDebit::OLD_IC                # 2
Bayarcash::FpxDirectDebit::PASSPORT              # 3
Bayarcash::FpxDirectDebit::BUSINESS_REGISTRATION # 4
Bayarcash::FpxDirectDebit::OTHERS                # 5

# Frequency mode
Bayarcash::FpxDirectDebit::MODE_DAILY   # "DL"
Bayarcash::FpxDirectDebit::MODE_WEEKLY  # "WK"
Bayarcash::FpxDirectDebit::MODE_MONTHLY # "MT"
Bayarcash::FpxDirectDebit::MODE_YEARLY  # "YR"
```

### 1. Enrolment

```ruby
data = {
  "portal_key"             => "your_portal_key",
  "order_number"           => "DD-1001",
  "amount"                 => "10.00", # range 5.00–30000.00
  "payer_name"             => "Ahmad bin Abdullah",
  "payer_id_type"          => Bayarcash::FpxDirectDebit::NRIC,
  "payer_id"               => "900101011234",
  "payer_email"            => "ahmad@example.com", # max 27 chars
  "payer_telephone_number" => "0123456789",
  "application_reason"     => "Monthly subscription",
  "frequency_mode"         => Bayarcash::FpxDirectDebit::MODE_MONTHLY,
  "effective_date"         => "2026-08-01", # optional, Y-m-d
  "expiry_date"            => "2027-08-01", # optional, Y-m-d
  "return_url"             => "https://your-site.com/mandate/return"
}

data["checksum"] = bayarcash.create_fpx_direct_debit_enrolment_checksum_value(api_secret_key, data)

mandate = bayarcash.create_fpx_direct_debit_enrollment(data)
redirect_to mandate.url # redirect payer to the enrolment page
```

### 2. Maintenance

Update an existing mandate (identified by its mandate id):

```ruby
data = {
  "amount"                 => "15.00",
  "payer_email"            => "ahmad@example.com",
  "payer_telephone_number" => "0123456789",
  "application_reason"     => "Update amount",
  "frequency_mode"         => Bayarcash::FpxDirectDebit::MODE_MONTHLY
}

data["checksum"] = bayarcash.create_fpx_direct_debit_maintenance_checksum_value(api_secret_key, data)

mandate = bayarcash.create_fpx_direct_debit_maintenance(mandate_id, data)
redirect_to mandate.url
```

### 3. Termination

```ruby
mandate = bayarcash.create_fpx_direct_debit_termination(mandate_id, {
  "application_reason" => "Customer cancelled"
})
redirect_to mandate.url
```

### Retrieving mandates & verifying mandate callbacks

```ruby
mandate     = bayarcash.get_fpx_direct_debit(mandate_id)
transaction = bayarcash.get_fpx_direct_debit_transaction(transaction_id)

# Mandate callback verifiers
bayarcash.verify_direct_debit_bank_approval_callback_data(callback_data, api_secret_key)
bayarcash.verify_direct_debit_authorization_callback_data(callback_data, api_secret_key)
bayarcash.verify_direct_debit_transaction_callback_data(callback_data, api_secret_key)
```

> The direct-debit **authorization** verifier includes the `application_type` field, exactly
> as the gateway signs it.

## Manual Bank Transfer

Submit a manual (offline) bank transfer with proof of payment:

```ruby
response = bayarcash.create_manual_bank_transfer({
  "portal_key"                   => "your_portal_key",
  "payment_gateway"              => Bayarcash::Client::MANUAL_TRANSFER, # must be 2
  "order_no"                     => "MT-1001",
  "buyer_name"                   => "Ahmad bin Abdullah",
  "buyer_email"                  => "ahmad@example.com",
  "buyer_tel_no"                 => "0123456789", # optional
  "order_amount"                 => "10.00",
  "merchant_bank_name"           => "Maybank",
  "merchant_bank_account"        => "1234567890",
  "merchant_bank_account_holder" => "Your Company Sdn Bhd",
  "bank_transfer_type"           => "Internet Banking", # or "Cash Deposit Machine (CDM)"
  "bank_transfer_notes"          => "Payment for order MT-1001",
  "bank_transfer_date"           => "2026-07-22", # optional, defaults to today
  "proof_of_payment"             => "/path/to/receipt.jpg" # jpeg/png/gif/pdf, max 10 MB
})
```

Update the status of an existing transfer:

```ruby
bayarcash.update_manual_bank_transfer_status(
  "ref_no_here",
  Bayarcash::Fpx::STATUS_SUCCESS.to_s,
  "10.00"
)
```

## Portals & FPX Banks

```ruby
# All portals for your account
portals = bayarcash.get_portals

# Payment channels available for a portal
channels = bayarcash.get_channels("your_portal_key")

# FPX banks (for building a bank selector)
banks = bayarcash.fpx_banks_list
```

## Error Handling

Failed API calls raise typed errors. Rescue them to handle failures gracefully:

```ruby
begin
  payment_intent = bayarcash.create_payment_intent(data)
rescue Bayarcash::ValidationError => e
  # 422 — invalid request data
  errors = e.errors
rescue Bayarcash::NotFoundError => e
  # 404 — resource not found
rescue Bayarcash::RateLimitExceededError => e
  # 429 — too many requests
  reset_at = e.rate_limit_resets_at # unix timestamp or nil
rescue Bayarcash::FailedActionError => e
  # 400 — request failed
  message = e.message
end
```

| Error | HTTP | Meaning |
|---|---|---|
| `Bayarcash::ValidationError` | 422 | Invalid data. Call `#errors` for details. |
| `Bayarcash::FailedActionError` | 400 | Request failed. `#message` has the reason. |
| `Bayarcash::NotFoundError` | 404 | Resource not found. |
| `Bayarcash::RateLimitExceededError` | 429 | Rate limited. `#rate_limit_resets_at` holds the reset time. |
| `Bayarcash::TimeoutError` | — | Raised by the optional `retry_until` helper after a timeout. |
| `Bayarcash::Error` | other | Base class; also raised for any other non-2xx status. |

## Response Objects

API methods return typed resource objects with snake_case readers. Common properties:

**`PaymentIntentResource`** (from `create_payment_intent` / `get_payment_intent`)

```ruby
payment_intent.url          # checkout URL to redirect the payer to
payment_intent.id
payment_intent.status
payment_intent.amount
payment_intent.order_number
payment_intent.payer_name
payment_intent.payer_email
```

**`TransactionResource`** (from `get_transaction` / transaction queries)

```ruby
transaction.id
transaction.status                    # status code — see Fpx constants
transaction.status_description
transaction.amount
transaction.order_number
transaction.exchange_reference_number
transaction.payer_name
transaction.payer_email
```

Any missing field is `nil`. Convert a resource (including nested resources) to a hash:

```ruby
transaction.to_h
```

## Security Recommendations

1. Always send a `checksum` with payment and mandate requests.
2. Verify **every** callback with the provided verification methods before acting on it.
3. Store and check transaction ids to prevent duplicate processing.
4. Use HTTPS for your `return_url` and `callback_url`.
5. Keep your API token and secret key out of source control.

## Development

```bash
bundle install
bundle exec rspec
```

## API Documentation

For full API details, see the [Official Bayarcash API Documentation](https://api.webimpian.support/bayarcash).

## Support

For support questions, contact Bayarcash support or open an issue in this repository.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for the version history.

## License

Open-sourced software licensed under the [MIT license](LICENSE).
