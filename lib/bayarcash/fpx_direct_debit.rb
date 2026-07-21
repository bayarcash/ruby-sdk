# frozen_string_literal: true

module Bayarcash
  # FPX Direct Debit constants: application types, payer id types, frequency modes,
  # and mandate status codes, together with their human-readable labels.
  class FpxDirectDebit
    # Application type
    ENROLMENT   = "01"
    MAINTENANCE = "02"
    TERMINATION = "03"

    # Buyer / payer ID type
    NRIC                  = 1
    OLD_IC                = 2
    PASSPORT              = 3
    BUSINESS_REGISTRATION = 4
    OTHERS                = 5

    # Frequency mode
    MODE_DAILY   = "DL"
    MODE_WEEKLY  = "WK"
    MODE_MONTHLY = "MT"
    MODE_YEARLY  = "YR"

    # Status code
    STATUS_NEW                     = 0
    STATUS_WAITING_APPROVAL        = 1
    STATUS_FAILED_BANK_VERIFICATION = 2
    STATUS_ACTIVE                  = 3
    STATUS_TERMINATED              = 4
    STATUS_APPROVED                = 5
    STATUS_REJECTED                = 6
    STATUS_CANCELLED               = 7
    STATUS_ERROR                   = 8

    STATUS_LABELS = {
      STATUS_NEW                      => "New",
      STATUS_WAITING_APPROVAL         => "Waiting Approval",
      STATUS_FAILED_BANK_VERIFICATION => "Bank Verification Failed",
      STATUS_APPROVED                 => "Approved",
      STATUS_REJECTED                 => "Rejected",
      STATUS_CANCELLED                => "Cancelled",
      STATUS_ERROR                    => "Error",
      STATUS_ACTIVE                   => "Active",
      STATUS_TERMINATED               => "Terminated"
    }.freeze

    # @param status_code [Integer]
    # @return [String] label for the status, or "UNKNOWN STATUS"
    def self.get_status_text(status_code)
      STATUS_LABELS.fetch(status_code.to_i, "UNKNOWN STATUS")
    end

    # @param application_type [String] one of {ENROLMENT}, {MAINTENANCE}, {TERMINATION}
    # @return [String, nil]
    def self.get_application_type_text(application_type)
      case application_type
      when ENROLMENT   then "Enrollment"
      when MAINTENANCE then "Maintenance"
      when TERMINATION then "Termination"
      end
    end

    # @param frequency_mode_code [String] one of {MODE_DAILY}, {MODE_WEEKLY}, {MODE_MONTHLY}, {MODE_YEARLY}
    # @return [String, nil]
    def self.get_frequency_mode_text(frequency_mode_code)
      case frequency_mode_code
      when MODE_DAILY   then "Daily"
      when MODE_WEEKLY  then "Weekly"
      when MODE_MONTHLY then "Monthly"
      when MODE_YEARLY  then "Yearly"
      end
    end
  end
end
