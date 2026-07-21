# frozen_string_literal: true

module Bayarcash
  module Resources
    # Returned by direct-debit enrolment, maintenance and termination calls.
    class FpxDirectDebitApplicationResource < Resource
      attributes :payer_name, :payer_id_type, :payer_id, :payer_email,
                 :payer_telephone_number, :order_number, :amount, :application_type,
                 :application_reason, :frequency_mode, :effective_date, :expiry_date, :url
    end
  end
end
