# frozen_string_literal: true

module Bayarcash
  module Resources
    # Returned by transaction lookups and queries.
    class TransactionResource < Resource
      attributes :id, :updated_at, :created_at, :datetime, :payer_name, :payer_email,
                 :payer_telephone_number, :order_number, :currency, :amount,
                 :exchange_reference_number, :exchange_transaction_id, :payer_bank_name,
                 :status, :status_description, :return_url, :metadata, :payout,
                 :payment_gateway, :portal, :merchant, :mandate
    end
  end
end
