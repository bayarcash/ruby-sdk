# frozen_string_literal: true

module Bayarcash
  module Resources
    # Returned by {Bayarcash::Client#get_portals}.
    class PortalResource < Resource
      attributes :id, :created_at, :portal_key, :portal_name, :website_url,
                 :transaction_notification_email, :secondary_transaction_notification_email,
                 :custom_payment_button_text, :enabled_sms_on_successful_transaction,
                 :split_payment_enabled, :split_payment_merchants, :payment_channels,
                 :merchant, :url, :merchant_id
    end
  end
end
