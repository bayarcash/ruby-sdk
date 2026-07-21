# frozen_string_literal: true

module Bayarcash
  # FPX Direct Debit mandate operations (enrolment, maintenance, termination) and
  # mandate/transaction retrieval.
  module FpxDirectDebitPaymentIntent
    # Enrol a new direct-debit mandate.
    #
    # @param data [Hash]
    # @return [Bayarcash::Resources::FpxDirectDebitApplicationResource]
    def create_fpx_direct_debit_enrollment(data)
      Bayarcash::Resources::FpxDirectDebitApplicationResource.new(
        post("mandates", data),
        self
      )
    end

    # Maintain (update) an existing mandate.
    #
    # @param mandate_id [String]
    # @param data [Hash]
    # @return [Bayarcash::Resources::FpxDirectDebitApplicationResource]
    def create_fpx_direct_debit_maintenance(mandate_id, data)
      Bayarcash::Resources::FpxDirectDebitApplicationResource.new(
        put("mandates/#{mandate_id}", data),
        self
      )
    end

    # Terminate an existing mandate.
    #
    # @param mandate_id [String]
    # @param data [Hash]
    # @return [Bayarcash::Resources::FpxDirectDebitApplicationResource]
    def create_fpx_direct_debit_termination(mandate_id, data)
      Bayarcash::Resources::FpxDirectDebitApplicationResource.new(
        delete("mandates/#{mandate_id}", data),
        self
      )
    end

    # Retrieve a direct-debit mandate transaction.
    #
    # @param id [String]
    # @return [Bayarcash::Resources::TransactionResource]
    def get_fpx_direct_debit_transaction(id)
      Bayarcash::Resources::TransactionResource.new(
        get("mandates/transactions/#{id}"),
        self
      )
    end

    # Deprecated misspelled alias, kept for backward compatibility.
    #
    # @deprecated Use {#get_fpx_direct_debit_transaction} instead.
    def getfpx_direct_debitransaction(id)
      get_fpx_direct_debit_transaction(id)
    end

    # Retrieve a direct-debit mandate.
    #
    # @param id [String]
    # @return [Bayarcash::Resources::FpxDirectDebitResource]
    def get_fpx_direct_debit(id)
      Bayarcash::Resources::FpxDirectDebitResource.new(
        get("mandates/#{id}")
      )
    end
  end
end
