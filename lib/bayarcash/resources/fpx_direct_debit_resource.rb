# frozen_string_literal: true

module Bayarcash
  module Resources
    # Returned by {Bayarcash::Client#get_fpx_direct_debit} (a mandate).
    class FpxDirectDebitResource < Resource
      attributes :id, :updated_at, :mandate_reference_number, :order_number,
                 :application_reason, :frequency_mode, :frequency_mode_label,
                 :effective_date, :expiry_date, :currency, :amount, :payer_name,
                 :payer_id, :payer_id_type, :payer_bank_account_number, :payer_email,
                 :payer_telephone_number, :status, :status_description, :return_url,
                 :metadata, :portal, :merchant
    end
  end
end
