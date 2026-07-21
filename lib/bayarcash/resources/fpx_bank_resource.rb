# frozen_string_literal: true

module Bayarcash
  module Resources
    # Returned by {Bayarcash::Client#fpx_banks_list}.
    class FpxBankResource < Resource
      attributes :bank_name, :bank_display_name, :bank_code, :bank_code_hashed,
                 :bank_availability
    end
  end
end
