# frozen_string_literal: true

require "json"
require "openssl"
require "uri"
require "date"
require "faraday"
require "faraday/multipart"

require_relative "bayarcash/version"
require_relative "bayarcash/errors"
require_relative "bayarcash/security_utils"
require_relative "bayarcash/util"

require_relative "bayarcash/resources/resource"
require_relative "bayarcash/resources/payment_intent_resource"
require_relative "bayarcash/resources/transaction_resource"
require_relative "bayarcash/resources/portal_resource"
require_relative "bayarcash/resources/fpx_bank_resource"
require_relative "bayarcash/resources/fpx_direct_debit_resource"
require_relative "bayarcash/resources/fpx_direct_debit_application_resource"

require_relative "bayarcash/fpx"
require_relative "bayarcash/fpx_direct_debit"
require_relative "bayarcash/duit_now/dobw"

require_relative "bayarcash/checksum_generator"
require_relative "bayarcash/callback_verifications"
require_relative "bayarcash/makes_http_requests"
require_relative "bayarcash/fpx_direct_debit_payment_intent"
require_relative "bayarcash/manual_bank_transfer"

require_relative "bayarcash/client"

# Bayarcash Ruby SDK.
#
# The primary entry point is {Bayarcash::Client}, an expressive, framework-agnostic
# client for the Bayarcash Payment Gateway API. It mirrors the public surface of the
# official PHP SDK while remaining idiomatic Ruby.
module Bayarcash
end
