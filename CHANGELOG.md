# Changelog

All notable changes to this project will be documented in this file.

## 3.0.0 - 2026-07-22

### Added
- Initial release of the Ruby SDK for the Bayarcash payment gateway — an idiomatic,
  framework-agnostic port of the official PHP SDK.
- Support for API **v2** (default) and **v3**, including the v3-only transaction
  queries, payment-intent retrieval and cancellation.
- Checksum generation (HMAC-SHA256) for payment intents and FPX Direct Debit
  enrolment/maintenance, byte-compatible with the gateway.
- Callback verification for every callback type (pre-transaction, transaction,
  return-url, direct-debit bank approval, authorization and transaction) using a
  constant-time checksum comparison.
- FPX Direct Debit mandate operations and Manual Bank Transfer (with multipart
  `proof_of_payment` upload and status update).
- Payment-channel constants, status classes (`Fpx`, `FpxDirectDebit`,
  `DuitNow::Dobw`), and typed response objects tolerant of omitted fields.
- Typed errors mapping HTTP status codes (422, 404, 400, 429 and a generic fallback).
