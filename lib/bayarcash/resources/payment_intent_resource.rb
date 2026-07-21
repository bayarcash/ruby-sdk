# frozen_string_literal: true

module Bayarcash
  module Resources
    # Returned by {Bayarcash::Client#create_payment_intent} and
    # {Bayarcash::Client#get_payment_intent}.
    class PaymentIntentResource < Resource
      attributes :payer_name, :payer_email, :payer_telephone_number, :order_number,
                 :amount, :url, :type, :id, :status, :last_attempt, :paid_at,
                 :currency, :attempts
    end
  end
end
