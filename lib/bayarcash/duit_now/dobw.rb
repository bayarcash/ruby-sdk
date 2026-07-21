# frozen_string_literal: true

module Bayarcash
  module DuitNow
    # DuitNow Online Banking / Wallet (DOBW) account types and status codes.
    class Dobw
      CASA        = "01"
      CREDIT_CARD = "02"
      EWALLET     = "03"

      # Status code
      STATUS_NEW       = 0
      STATUS_PENDING   = 1
      STATUS_FAILED    = 2
      STATUS_SUCCESS   = 3
      STATUS_CANCELLED = 4

      STATUS_LABELS = {
        STATUS_NEW       => "New",
        STATUS_PENDING   => "Pending",
        STATUS_CANCELLED => "Cancelled",
        STATUS_SUCCESS   => "Successful",
        STATUS_FAILED    => "Failed"
      }.freeze

      # @param status_code [Integer]
      # @return [String] label for the status, or "UNKNOWN STATUS"
      def self.get_status_text(status_code)
        STATUS_LABELS.fetch(status_code.to_i, "UNKNOWN STATUS")
      end
    end
  end
end
