# Agreement Payment API Documentation

**Document Version**: v2.11

**Update Date**: 2026-06-09

**Update History**:
- v2.11: Added REJECTED agreement status (user actively canceled signing); Sign-with-pay Webhook changed to independent notifications to signNotifyUrl/payNotifyUrl; Added sign rejected notification (eventType=REJECTED) and sign failed notification (eventType=AGREEMENT_SIGN_RESULT); Added EXPIRED event type; Fixed timeout handling description (timeout does send Webhook notification); Completed all eventType enum tables
- v2.10: Added merchant settlement configuration error code MERCHANT_SETTLEMENT_CONFIG_ERROR (139006004); Added merchant quota limit error code EXCEED_MERCHANT_QUOTA_LIMIT (139004008); Added chainAddress field to amount and limit config in sign/deduction/sign-and-pay APIs
- v2.9: Added Agreement Type Description section (7.5) detailing the usage scenarios and limit configuration differences for CYCLE/NON_CYCLE/SINGLE types; Fixed 4 instances of missing NON_CYCLE in English documentation
- v2.8: Expanded agreement pay API supported scene codes from 6 to 17 (added FOOD/ENTERTAINMENT/EDUCATION/MEMBERSHIP/RENT/FITNESS/TELECOM/CLOUD/INSURANCE/LOAN/OTHERS), fully consistent with sign API scene codes
- v2.7: Fixed unsign API failure response example field names (code→retCode, message→retMsg); Fixed rate limiting response format field names
- v2.6: Fixed failure response format field names (code→retCode, message→retMsg); Fixed extraParams type description (object→string JSON string); Adjusted section order (3.5 deduction refund API moved to correct position)
- v2.5: Fixed success response code from 0 to 20000 (aligned with ResultCode.SUCCESS); Fixed success response message from "success" to "Success"; All API response examples fully consistent with actual code implementation
- v2.4: Fixed response format field names (code→retCode, message→retMsg, data→result); Fixed error code numbers (UNAUTHORIZED=40002, PARAM_INVALID=40001); Removed redundant userId field from sign request example; Added NON_CYCLE type description; All API examples fully aligned with Proto definition
- v2.3: Fixed chapter numbering (3.3-3.9), refund API number adjusted to 3.5; Added agreementNo and externalAgreementNo fields in sign request response; Added signValidTime validation requirement (must be at least 24 hours after current time); Optimized productCode field description; Chinese and English documentation fully aligned
- v2.2: Webhook signature mechanism optimized: Signature parameters moved from request body to HTTP Headers (X-Signature/X-Timestamp/X-Nonce/X-Sign-Type), fresh signature generated for each send/retry, request body remains pure JSON; Fixed document TOC chapter numbering (4.7-4.9)
- v2.1: Internal optimization of deduction API: Support user-defined limit verification (users can set single/daily limits through cashier), downstream payment uses user-configured paymentType (payNow/payLater)
- v2.0: Async notification parameter table supplemented with notifyId/notifyTime common fields (4.1-4.6); Deduction API supplemented with fiat currency order request example (3.4); Webhook section added complete Java/Python/Node.js handling code examples (4.7); Signature algorithm section added complete cURL request example (5.4)
- v1.9: bindingInfo field naming unified; refundAmount.total field structure standardized; Added complete status response examples for sign confirmation/unsign/refund APIs; Added sign/refund notification failure examples; Deduction status added TIMEOUT; Added extraParams and sceneInfo.location field descriptions; Error codes grouped by module; Added chain network list (7.3); Added rate limiting description (2.10); Added sandbox environment description (7.5); Fixed notifyId duplication issue
- v1.8: Unified sceneCode enum values; Corrected bindStatus enum; Sign limit configuration supports chain field; Transaction list API supplemented REFUND response; Added API timeout recommendations and concurrency handling description; Added refund status flow diagram; Added API version compatibility description; Added riskInfo risk control field; Added failure response and PROCESSING status examples; Added document directory
- v1.7: Added agreement list query API; Transaction query API merged refund query (distinguished by recordType); Transaction list API supports refund record query; Added general specification section (request headers, response format, HTTP status codes, field length limits, idempotency, transaction status flow); GET API examples changed to Query String format; Webhook notification added notifyId deduplication field; Refund notification added userId field; Sign request added signExpireMinutes parameter
- v1.6: Moved business flow diagrams and sign lifecycle state machine to Chapter 1 Overview; API paths unified to start with /v5/pay/agreement; Added currency type (fiat/cryptocurrency) support; Added request and response examples for all APIs
- v1.5: Clearly distinguished userId (platform user ID) and merchantUserId (merchant-side user ID); All APIs unified required common fields (merchantId, userId, agreementType); Sign API added merchantUserId for establishing merchant-side to platform-side user mapping
- v1.4: Unified all API required common fields (merchantId, userId, agreementType)
- v1.3: Optimized sign flow, supports QR code sign; Added user identity association mechanism; Updated sign request to return QR code
- v1.2: Added sign lifecycle state machine (state definition, state transition diagram, state transition description, allowed operations per state)
- v1.1: Added refund API, refund query API, agreement unsign Webhook, refund result Webhook
- v1.0: Initial version

---

## Table of Contents

- [1. API Overview](#1-api-overview)
  - [1.1 User Identity Association and Sign Flow](#11-user-identity-association-and-sign-flow)
  - [1.2 Sign Sequence Diagram](#12-sign-sequence-diagram)
  - [1.3 Deduction Flow](#13-deduction-flow)
  - [1.4 Refund Flow](#14-refund-flow)
  - [1.5 Unsign Notification Flow](#15-unsign-notification-flow)
  - [1.6 Sign Lifecycle State Machine](#16-sign-lifecycle-state-machine)
- [2. Core API List](#2-core-api-list)
  - [2.1 Common Request Headers](#21-common-request-headers)
  - [2.2 Common Response Format](#22-common-response-format)
  - [2.3 HTTP Status Code Mapping](#23-http-status-code-mapping)
  - [2.4 Field Length Limits](#24-field-length-limits)
  - [2.5 Idempotency Description](#25-idempotency-description)
  - [2.6 API Timeout Recommendations](#26-api-timeout-recommendations)
  - [2.7 Concurrency Handling Description](#27-concurrency-handling-description)
  - [2.8 Deduction Transaction Status Flow](#28-deduction-transaction-status-flow)
  - [2.9 Refund Status Flow](#29-refund-status-flow)
  - [2.10 Rate Limiting Description](#210-rate-limiting-description)
- [3. API Details](#3-api-details)
  - [3.1 Sign Request API](#31-sign-request-api)
  - [3.2 Unsign API](#32-unsign-api)
  - [3.3 Agreement Deduction API (Core)](#33-agreement-deduction-api-core)
  - [3.4 Pay with Sign API (One-Step)](#34-pay-with-sign-api-one-step)
  - [3.5 Deduction Refund API](#35-deduction-refund-api)
  - [3.6 Sign Status Query API](#36-sign-status-query-api)
  - [3.7 Agreement List Query API](#37-agreement-list-query-api)
  - [3.8 Transaction/Refund Query API (Single)](#38-transactionrefund-query-api-single)
  - [3.9 Deduction Transaction List API](#39-deduction-transaction-list-api)
- [4. Async Notifications](#4-async-notifications)
  - [4.1 Sign Result Notification](#41-sign-result-notification)
  - [4.2 Deduction Result Notification](#42-deduction-result-notification)
  - [4.3 Agreement Unsign Notification](#43-agreement-unsign-notification)
  - [4.4 Refund Result Notification](#44-refund-result-notification)
  - [4.5 Agreement Suspend Notification](#45-agreement-suspend-notification)
  - [4.6 Agreement Resume Notification](#46-agreement-resume-notification)
  - [4.7 Sign Timeout Notification](#47-sign-timeout-notification)
  - [4.8 Order Timeout Notification](#48-order-timeout-notification)
  - [4.9 Webhook General Description](#49-webhook-general-description)
- [5. Security Mechanism](#5-security-mechanism)
  - [5.1 Sign Security](#51-sign-security)
  - [5.2 Deduction Security](#52-deduction-security)
  - [5.3 API Security](#53-api-security)
  - [5.4 Signature Algorithm Detailed Description](#54-signature-algorithm-detailed-description)
- [6. Error Codes](#6-error-codes)
  - [6.0 Common Success](#60-common-success)
  - [6.1 Common Error Codes](#61-common-error-codes)
  - [6.2 Agreement Related Error Codes](#62-agreement-related-error-codes)
  - [6.3 Transaction Related Error Codes](#63-transaction-related-error-codes)
  - [6.4 Refund Related Error Codes](#64-refund-related-error-codes)
  - [6.5 Currency/Amount Related Error Codes](#65-currencyamount-related-error-codes)
  - [6.6 Security/Authentication Related Error Codes](#66-securityauthentication-related-error-codes)
  - [6.7 Merchant/User Related Error Codes](#67-merchantuser-related-error-codes)
  - [6.8 Order Related Error Codes](#68-order-related-error-codes)
  - [6.9 System Error Codes](#69-system-error-codes)
  - [6.10 Downstream Error Code Mapping](#610-downstream-error-code-mapping)
- [7. Appendix](#7-appendix)
  - [7.1 Scene Code List](#71-scene-code-list)
  - [7.2 Currency List](#72-currency-list)
  - [7.3 Chain Network List](#73-chain-network-list)
  - [7.4 Amount Precision Description](#74-amount-precision-description)
  - [7.5 Agreement Type Description](#75-agreement-type-description)
  - [7.6 Sandbox Environment](#76-sandbox-environment)

---

## 1. API Overview

**Functional Description**: Agreement Payment supports contactless payment scenarios such as ride-hailing and subscriptions

**Applicable Scenarios**: Ride-hailing contactless payment, membership auto-renewal, utility bill payment, parking lot automatic deduction

**Security Mechanism**: Strong authentication for signing + Limit control + Risk control interception + Async notification

**API Version**: v5

**Version Compatibility Description**:
- All current API paths start with `/v5/pay/agreement`
- New fields are added in a backward-compatible manner, existing field semantics will not be deleted or modified
- Merchants should handle new optional fields in responses compatibly (ignore unknown fields)
- Major incompatible changes will be released through new version paths (e.g., /v6), with advance merchant notification

### 1.1 User Identity Association and Sign Flow

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                            User Identity Association and Sign Flow               │
├──────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│  1. Merchant App → Sign Request(userId + merchantUserId) → Platform returns      │
│     sign QR code and URL                                                         │
│                                                                                  │
│  2. User opens platform App to scan → Login/Register platform account →          │
│     Complete identity verification (SMS/Face/Password)                           │
│                                                                                  │
│  3. Platform binds user relationship:                                            │
│     userId(platform) binding merchantUserId(merchant-side)                       │
│                                                                                  │
│  4. Sign success → Webhook notifies merchant (agreementNo + userId +             │
│     merchantUserId)                                                              │
│                                                                                  │
│                                                                                  │
└──────────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 Sign Sequence Diagram

```
Merchant Server                  Platform                         User App
    │                         │                            │
    │  1.Sign Request         │                            │
    │  (userId +             │                            │
    │   merchantUserId)     │                            │
    │ ──────────────────────→ │                            │
    │                         │                            │
    │  2.Return Sign QR Code  │                            │
    │  (qrCode/signUrl)     │                            │
    │ ←────────────────────── │                            │
    │                         │                            │
    │     Display QR Code     │        3.Scan              │
    │ - - - - - - - - - - - - │ ←────────────────────────  │
    │                         │                            │
    │                         │     4.Login/Register       │
    │                         │ ←─────────────────────────→│
    │                         │                            │
    │                         │     5.Identity Verification│
    │                         │     (SMS/Face/Password)    │
    │                         │ ←─────────────────────────→│
    │                         │                            │
    │                         │     6.Confirm Sign Auth    │
    │                         │ ←────────────────────────  │
    │                         │                            │
    │  7.Webhook Notification │                            │
    │  (agreementNo +        │                            │
    │   userId +             │                            │
    │   merchantUserId)     │                            │
    │                         │                            │
    │ ←────────────────────── │                            │
    │                         │                            │
```

### 1.3 Deduction Flow

```
Merchant Server → Deduction Request(agreementNo) → Platform
                                      ↓
                            ┌─────────────────┐
                            │ 1. Agreement     │
                            │    validity check│
                            │ 2. Limit check   │
                            │ 3. Risk check    │
                            │ 4. Execute       │
                            │    deduction     │
                            └─────────────────┘
                                      ↓
   ←←←←←←← Sync return result + Async notification ←←←←

User receives deduction notification (Push/SMS)
```

### 1.4 Refund Flow

```
Merchant Server → Refund Request(tradeNo + refundAmount) → Platform
                                                   ↓
                                         ┌─────────────────┐
                                         │ 1. Transaction  │
                                         │    validity check│
                                         │ 2. Refundable   │
                                         │    amount check │
                                         │ 3. Execute refund│
                                         └─────────────────┘
                                                   ↓
   ←←←←←←← Sync return result + Async notification ←←←←←←←←

User receives refund notification (Push/SMS)
```

### 1.5 Unsign Notification Flow

```
User/System → Trigger unsign → Platform updates agreement status
                              ↓
                    Platform pushes unsign Webhook
                              ↓
                    Merchant receives and processes unsign notification
                              ↓
                    Merchant returns {"code": "SUCCESS"}
```

### 1.6 Sign Lifecycle State Machine

#### State Definition

| Status Code | Status Name | Description |
| --- | --- | --- |
| INIT | Initialized | Sign request created, waiting for user to scan |
| PENDING | Pending Confirmation | User initiated scan confirmation, waiting to complete sign |
| SIGNED | Signed | Agreement active, deduction allowed |
| SUSPENDED | Suspended | Agreement paused, deduction temporarily not allowed (can be resumed) |
| UNSIGNED | Unsigned | Agreement terminated (final state) |
| EXPIRED | Expired | Agreement expired automatically (final state) |
| REJECTED | Rejected | User actively canceled signing (final state) |
| FAILED | Sign Failed | System error caused sign process termination (final state) |
| TIMEOUT | Sign Timeout | Sign link/QR code expired (final state) |

#### State Transition Diagram

```
                                    ┌─────────────────────────────────────┐
                                    │                                     │
                                    ▼                                     │
┌──────┐  Sign Request  ┌──────┐  User Scan   ┌─────────┐  Cashier Confirm  ┌────────┐
│      │ ─────────────→ │      │ ───────────→ │         │ ─────────────→ │        │
│ Start│                │ INIT │              │ PENDING │                │ SIGNED │◀──┐
│      │                │      │              │         │                │        │   │
└──────┘                └──────┘              └─────────┘                └────────┘   │
                            │                    │ │                         │ │ │    │
                            │ Timeout(30min)     │ │ Sign Failed/Rejected    │ │ │    │
                            │                    │ ▼                         │ │ │    │
                            │               ┌────────┐                       │ │ │    │
                            │               │ FAILED │                       │ │ │    │
                            │               └────────┘                       │ │ │    │
                            │                    │                           │ │ │    │
                            │ Timeout(30min)     │                           │ │ │    │
                            ▼                    ▼                           │ │ │    │
                        ┌─────────┐         ┌─────────┐                      │ │ │    │
                        │ TIMEOUT │         │ TIMEOUT │                      │ │ │    │
                        └─────────┘         └─────────┘                      │ │ │    │
                                                                             │ │ │    │
                             ┌───────────────────────────────────────────────┘ │ │    │
                             │ User/Merchant/System Unsign                     │ │    │
                             ▼                                                 │ │    │
                        ┌──────────┐                                           │ │    │
                        │ UNSIGNED │                                           │ │    │
                        └──────────┘                                           │ │    │
                                                                               │ │    │
                             ┌─────────────────────────────────────────────────┘ │    │
                             │ Agreement Expired                                  │    │
                             ▼                                                   │    │
                        ┌─────────┐                                              │    │
                        │ EXPIRED │                                              │    │
                        └─────────┘                                              │    │
                                                                                 │    │
                             ┌───────────────────────────────────────────────────┘    │
                             │ Risk/Abnormal Suspend                                   │
                             ▼                                                        │
                        ┌───────────┐  Resume Agreement                               │
                        │ SUSPENDED │ ────────────────────────────────────────────────┘
                        └───────────┘
                             │
                             │ Unsign During Suspension
                             ▼
                        ┌──────────┐
                        │ UNSIGNED │
                        └──────────┘
```

#### State Transition Description

| Original State | Target State | Trigger Condition | Description |
| --- | --- | --- | --- |
| - | INIT | Merchant calls sign request API | Create sign order, generate sign link/QR code |
| INIT | PENDING | User initiates scan confirmation | User scans and initiates sign confirmation flow |
| INIT | TIMEOUT | Sign timeout (30 minutes) | Sign link/QR code expired, scheduled task auto-processes |
| PENDING | SIGNED | Cashier calls sign confirmation API | User completes scan sign, cashier callback confirms, agreement becomes active |
| PENDING | REJECTED | User rejected sign | User actively canceled signing on cashier page |
| PENDING | FAILED | Sign process abnormal | System error or payment failure in sign-with-pay scenario |
| PENDING | TIMEOUT | Sign timeout (30 minutes) | PENDING state timeout without completing sign, scheduled task auto-processes |
| SIGNED | UNSIGNED | User active unsign | User initiates unsign in App/platform |
| SIGNED | UNSIGNED | Merchant initiates unsign | Merchant calls unsign API |
| SIGNED | UNSIGNED | System unsign | Risk triggered, account abnormal, etc. system auto unsign |
| SIGNED | EXPIRED | Agreement expired | Reached validity period set at sign time |
| SIGNED | SUSPENDED | Risk suspend/abnormal suspend | Risk or abnormality detected, deduction capability paused |
| SUSPENDED | SIGNED | Resume agreement | Risk resolved, deduction capability restored |
| SUSPENDED | UNSIGNED | Unsign during suspension | User/merchant/system initiates unsign during suspension |

#### Allowed Operations Per State

| State | Deduction | Refund | Unsign | Query |
| --- | --- | --- | --- | --- |
| INIT | ✗ | ✗ | ✗ | ✓ |
| PENDING | ✗ | ✗ | ✗ | ✓ |
| SIGNED | ✓ | ✓ | ✓ | ✓ |
| SUSPENDED | ✗ | ✓ | ✓ | ✓ |
| UNSIGNED | ✗ | ✓ | ✗ | ✓ |
| EXPIRED | ✗ | ✓ | ✗ | ✓ |
| REJECTED | ✗ | ✗ | ✗ | ✓ |
| FAILED | ✗ | ✗ | ✗ | ✓ |
| TIMEOUT | ✗ | ✗ | ✗ | ✓ |

**Notes**:
- Deduction: Only SIGNED state can initiate new deductions
- Refund: Completed deduction transactions can still be refunded after agreement unsign/expire
- Unsign: Only SIGNED and SUSPENDED states can actively unsign
- Query: All states can be queried

#### Timeout Handling Mechanism

Sign timeout is auto-processed by scheduled task, scan conditions as follows:

```sql
SELECT * FROM t_agreement_user
WHERE status IN ('INIT', 'PENDING')
  AND create_time < NOW() - INTERVAL 30 MINUTE
```

**Processing Logic**:
1. Scheduled task executes every minute
2. Scan sign records in `INIT` or `PENDING` state with creation time over 30 minutes
3. Update status to `TIMEOUT`
4. Send sign timeout Webhook notification to merchant (eventType=TIMEOUT, see section 4.7)

**Notes**:
- Timeout is calculated from sign request creation time (`createTime`)
- Merchant can actively query sign result through sign status query API
- After timeout, merchant can re-initiate sign request

---

## 2. Core API List

| API Name | Request Method | Path |
| --- | --- | --- |
| Sign Request | POST | /v5/pay/agreement/sign |
| Unsign | POST | /v5/pay/agreement/unsign |
| Agreement Deduction | POST | /v5/pay/agreement/deduction |
| Pay with Sign | POST | /v5/pay/agreement/pay-with-sign |
| Deduction Refund | POST | /v5/pay/agreement/refund |
| Sign Status Query | GET | /v5/pay/agreement/query |
| Agreement List Query | GET | /v5/pay/agreement/list |
| Transaction/Refund Query | GET | /v5/pay/agreement/transaction/query |
| Transaction/Refund List | GET | /v5/pay/agreement/transaction/list |

### 2.1 Common Request Headers

All API requests must include the following request headers:

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| Content-Type | string | Yes | application/json |
| X-Request-Id | string | Yes | Request unique identifier (UUID format), used for idempotency and troubleshooting |
| X-Timestamp | string | Yes | Request timestamp (millisecond Unix timestamp) |
| X-Signature | string | Yes | Request signature (see 5.4 Signature Algorithm) |
| Authorization | string | Yes | Bearer {access_token} |

### 2.2 Common Response Format

#### Success Response

```json
{
  "retCode": 20000,
  "retMsg": "Success",
  "result": {
    // Business data
  }
}
```

#### Failure Response

```json
{
  "retCode": 40000,
  "retMsg": "Error description",
  "result": null
}
```

#### Response Field Description

| Parameter | Type | Description |
| --- | --- | --- |
| retCode | int | Response code, 20000-success, non-20000-failure |
| retMsg | string | Response message, "Success" on success, error description on failure |
| result | object/null | Response data, null on failure |

### 2.3 HTTP Status Code Mapping

| HTTP Status Code | Description | Applicable Scenario |
| --- | --- | --- |
| 200 | Request successful | Business processing success or failure (distinguished by code) |
| 400 | Request parameter error | Parameter format error, required parameter missing |
| 401 | Authentication failed | Token invalid or expired |
| 403 | Permission denied | IP not in whitelist, no API permission |
| 404 | Resource not found | API path error |
| 429 | Too many requests | Rate limit triggered |
| 500 | Internal server error | System exception, please retry |
| 503 | Service unavailable | System maintenance |

### 2.4 Field Length Limits

| Field Type | Max Length | Example Fields |
| --- | --- | --- |
| Merchant ID | 32 | merchantId |
| User ID | 64 | userId, merchantUserId |
| Agreement No | 64 | agreementNo, externalAgreementNo |
| Order No | 64 | outTradeNo, outRefundNo |
| Trade No | 64 | tradeNo, refundNo |
| Amount | 32 | amount.total |
| Currency Code | 16 | currency |
| URL | 512 | notifyUrl, returnUrl |
| Description | 256 | orderDesc, refundReason |
| Title | 128 | orderTitle |
| Extra Params | 2048 | extraParams (JSON string) |

### 2.5 Idempotency Description

Idempotency is guaranteed through business unique indexes:

| Business Scenario | Idempotency Key | Unique Index |
| --- | --- | --- |
| Sign Request | externalAgreementNo | (merchantId, externalAgreementNo) |
| Deduction Order | outTradeNo | (merchantId, outTradeNo) |
| Refund Request | outRefundNo | (merchantId, outRefundNo) |

- **X-Request-Id** is used for request tracing and troubleshooting
- X-Request-Id format requirement: UUID v4, e.g., `550e8400-e29b-41d4-a716-446655440000`
- Repeated requests with the same merchant order number (outTradeNo) return the result of the first request

### 2.6 API Timeout Recommendations

| API | Recommended Timeout | Description |
| --- | --- | --- |
| Sign Request | 10 seconds | Sync return sign link |
| Sign Confirmation | 10 seconds | Sync return sign status |
| Unsign | 10 seconds | Sync return unsign result |
| Agreement Deduction | 30 seconds | May involve on-chain operations, recommend longer timeout |
| Deduction Refund | 30 seconds | May involve on-chain operations, recommend longer timeout |
| Query APIs | 10 seconds | Sync return query result |

**Timeout Handling Recommendations**:
- After timeout, call query API to confirm actual status, avoid duplicate requests
- Deduction and refund API timeout does not mean failure, need to confirm final status through query or wait for async notification

### 2.7 Concurrency Handling Description

**Same Agreement Concurrent Deductions**:
- Same agreement supports concurrent initiation of multiple deduction requests
- Each deduction needs to use different `outTradeNo`
- Limit verification is based on real-time used quota, concurrent requests may cause some requests to be rejected due to exceeding quota

**Same Order Repeated Requests**:
- Requests with the same `outTradeNo` are treated as the same transaction
- After the first request succeeds, repeated requests return the first result (idempotent)
- After the first request fails, can use a new `outTradeNo` to re-initiate

### 2.8 Deduction Transaction Status Flow

```
                    ┌─────────────┐
                    │  PROCESSING │
                    │  (Processing)│
                    └──────┬──────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
    ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
    │   SUCCESS   │ │   FAILED    │ │   TIMEOUT   │
    │   (Success) │ │   (Failed)  │ │   (Timeout) │
    └─────────────┘ └─────────────┘ └─────────────┘
```

| Status | Description | Follow-up Actions |
| --- | --- | --- |
| PROCESSING | Deduction processing | Wait for async notification or actively query |
| SUCCESS | Deduction successful | Can initiate refund |
| FAILED | Deduction failed | Can re-initiate deduction (use new order number) |
| TIMEOUT | Deduction timeout | Query to confirm status first, then decide whether to retry |

### 2.9 Refund Status Flow

```
                    ┌─────────────┐
                    │  PROCESSING │
                    │  (Processing)│
                    └──────┬──────┘
                           │
                ┌──────────┴──────────┐
                │                     │
                ▼                     ▼
         ┌─────────────┐       ┌─────────────┐
         │   SUCCESS   │       │   FAILED    │
         │   (Success) │       │   (Failed)  │
         └─────────────┘       └─────────────┘
```

| Status | Description | Follow-up Actions |
| --- | --- | --- |
| PROCESSING | Refund processing | Wait for async notification or actively query |
| SUCCESS | Refund successful | Refund completed, funds returned to user |
| FAILED | Refund failed | Can check reason and re-initiate refund (use new refund order number) |

**Refund Notes**:
- Refund amount cannot exceed original transaction refundable amount (original transaction amount - refunded amount)
- Same transaction supports multiple partial refunds
- After successful refund, agreement's used quota will be restored accordingly

### 2.10 Rate Limiting Description

#### Rate Limiting Strategy

| API Type | Rate Limit Dimension | Rate Limit Threshold | Description |
| --- | --- | --- | --- |
| Sign Request | Merchant + User | 10 times/minute | Sign requests from same merchant for same user |
| Agreement Deduction | Merchant | 1000 times/second | Merchant-level QPS limit |
| Agreement Deduction | Agreement | 10 times/second | Single agreement deduction frequency |
| Query APIs | Merchant | 5000 times/second | All query APIs shared |
| Refund API | Merchant | 500 times/second | Merchant-level refund rate limit |

#### Rate Limit Response

When rate limit is triggered, API returns HTTP status code `429`, response body as follows:

```json
{
  "retCode": 42900,
  "retMsg": "Too many requests, please try again later",
  "result": {
    "retryAfter": 1000
  }
}
```

| Field | Description |
| --- | --- |
| retryAfter | Recommended retry wait time (milliseconds) |

#### Handling Recommendations

1. **Exponential Backoff**: After triggering rate limit, recommend using exponential backoff strategy for retry (e.g., 1s, 2s, 4s, 8s)
2. **Request Merging**: For batch query scenarios, recommend using list query API instead of multiple single queries
3. **Async Processing**: In high concurrency scenarios, recommend using message queue for peak shaving
4. **Monitoring Alerts**: Recommend monitoring 429 response ratio, adjust request strategy in time

---

## 3. API Details

### 3.1 Sign Request API

**Request Path**: POST /v5/pay/agreement/sign

#### Request Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| merchantId | string | Yes | Merchant ID |
| agreementType | string | Yes | Sign type: CYCLE(periodic deduction) / NON_CYCLE(non-periodic deduction) / SINGLE(single authorization) |
| merchantUserId | string | No | Merchant-side user ID (optional, used for merchant internal user association. If not provided, agreement will only be bound to platform userId) |
| sceneCode | string | Yes | Scene code (see 7.1 Scene Code List): TAXI/PARKING/SUBSCRIPTION/UTILITY/TOLL/TRANSIT/FOOD/ENTERTAINMENT/EDUCATION/MEMBERSHIP/RENT/FITNESS/TELECOM/CLOUD/INSURANCE/LOAN/OTHERS |
| productCode | string | Yes | Product code, assigned by platform |
| externalAgreementNo | string | Yes | Merchant agreement number (unique on merchant side) |
| signValidTime | string | No | Sign validity period, ISO8601 format (UTC timezone), **must be at least 24 hours after current time** |
| singleLimit | object | No | Single transaction limit configuration |
| singleLimit.amount | string | No | Limit amount (required when passing singleLimit) |
| singleLimit.currency | string | No | Currency code (required when passing singleLimit) |
| singleLimit.currencyType | string | No | Currency type: FIAT(fiat) / CRYPTO(cryptocurrency) (required when passing singleLimit) |
| singleLimit.chain | string | No | Chain network (optional for cryptocurrency, e.g.: ERC20/TRC20/Arbitrum) |
| singleLimit.chainAddress | string | No | Chain address (required for dynamic on-chain settlement) |
| periodLimits | array | No | Period limit configuration list (supports configuring limits for multiple period types) |
| periodLimits[].periodType | string | No | Period type: DAY/WEEK/MONTH/YEAR (required when passing periodLimits) |
| periodLimits[].amount | string | No | Period limit amount (required when passing periodLimits) |
| periodLimits[].currency | string | No | Currency code (required when passing periodLimits) |
| periodLimits[].currencyType | string | No | Currency type: FIAT(fiat) / CRYPTO(cryptocurrency) (required when passing periodLimits) |
| periodLimits[].chain | string | No | Chain network (optional for cryptocurrency, e.g.: ERC20/TRC20/Arbitrum) |
| periodLimits[].chainAddress | string | No | Chain address (required for dynamic on-chain settlement) |
| notifyUrl | string | Yes | Sign result async notification URL |
| returnUrl | string | No | Redirect URL after sign completion (can be omitted for App scan scenario) |
| signExpireMinutes | int | No | Sign link validity period (minutes), default 30, max 1440 (24 hours) |
| extraParams | string | No | Extension parameters (JSON string, used for passing business custom data, platform passes through without processing) |

#### Request Example

```json
{
  "merchantId": "M123456789",
  "agreementType": "CYCLE",
  "merchantUserId": "merchant_user_123",
  "sceneCode": "SUBSCRIPTION",
  "productCode": "PROD_001",
  "externalAgreementNo": "MERCHANT_AGR_001",
  "signValidTime": "2026-12-23T10:30:00Z",
  "singleLimit": {
    "amount": "100000",
    "currency": "USDT",
    "currencyType": "CRYPTO",
    "chain": "TRC20"
  },
  "periodLimits": [
    {
      "periodType": "DAY",
      "amount": "500000",
      "currency": "USDT",
      "currencyType": "CRYPTO",
      "chain": "TRC20"
    }
  ],
  "notifyUrl": "https://merchant.com/notify/sign",
  "returnUrl": "https://merchant.com/return",
  "signExpireMinutes": 60
}
```

#### Response Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| retCode | int | Response code, 20000-success, non-20000-failure |
| retMsg | string | Response message |
| result | object | Response data |
| result.signOrderId | string | Platform sign order number |
| result.signUrl | string | Sign page URL (for H5 redirect) |
| result.qrCode | string | Sign QR code content (for user App scan) |
| result.qrCodeUrl | string | Sign QR code image URL (can be displayed directly) |
| result.expireTime | string | Sign link/QR code expiration time |

#### Response Example (Success)

```json
{
  "retCode": 20000,
  "retMsg": "Success",
  "result": {
    "signOrderId": "AGR202312230001",
    "signUrl": "https://pay.example.com/sign?token=xxx",
    "qrCode": "https://pay.example.com/sign?token=xxx",
    "qrCodeUrl": "https://pay.example.com/qr/AGR202312230001.png",
    "expireTime": "2023-12-23T12:30:00Z"
  }
}
```

#### Response Example (Failure)

```json
{
  "retCode": 40001,
  "retMsg": "Parameter error: externalAgreementNo already exists",
  "result": null
}
```

---

---

### 3.2 Unsign API

**Request Path**: POST /v5/pay/agreement/unsign

#### Request Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| merchantId | string | Yes | Merchant ID |
| userId | string | Yes | Platform user ID (our platform's user identifier) |
| agreementType | string | Yes | Sign type: CYCLE(periodic deduction) / NON_CYCLE(non-periodic deduction) / SINGLE(single authorization) |
| agreementNo | string | Either | Platform agreement number |
| externalAgreementNo | string | Either | Merchant agreement number |
| unsignType | string | No | Unsign type: USER(user active)/MERCHANT(merchant initiated)/SYSTEM(system unsign) |
| unsignReason | string | No | Unsign reason |

#### Request Example

```json
{
  "merchantId": "M123456789",
  "userId": "U_123456789",
  "agreementType": "CYCLE",
  "agreementNo": "AGR202312230001",
  "unsignType": "USER",
  "unsignReason": "User active unsign"
}
```

#### Response Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| retCode | int | Response code, 20000-success, non-20000-failure |
| retMsg | string | Response message |
| result | object | Response data |
| result.agreementNo | string | Platform agreement number |
| result.status | string | Status: UNSIGNED |
| result.unsignTime | string | Unsign time |

#### Response Example (Success)

```json
{
  "retCode": 20000,
  "retMsg": "Success",
  "result": {
    "agreementNo": "AGR202312230001",
    "eventType": "UNSIGNED",
    "status": "UNSIGNED",
    "unsignTime": "2023-12-23T15:30:00Z"
  }
}
```

#### Response Example (Failure - Agreement Not Exist)

```json
{
  "retCode": 40003,
  "retMsg": "Agreement does not exist",
  "result": null
}
```

#### Response Example (Failure - Agreement Already Unsigned)

```json
{
  "retCode": 40004,
  "retMsg": "Agreement already unsigned, no need to repeat",
  "result": null
}
```

---

### 3.3 Agreement Deduction API (Core)

**Request Path**: POST /v5/pay/agreement/deduction

#### Request Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| merchantId | string | Yes | Merchant ID |
| userId | string | Yes | Platform user ID (our platform's user identifier) |
| agreementType | string | Yes | Sign type: CYCLE(periodic deduction) / NON_CYCLE(non-periodic deduction) / SINGLE(single authorization) |
| agreementNo | string | Yes | Platform agreement number |
| outTradeNo | string | Yes | Merchant order number (unique on merchant side) |
| sceneCode | string | Yes | Scene code (see 7.1 Scene Code List): TAXI/PARKING/SUBSCRIPTION/UTILITY/TOLL/TRANSIT/FOOD/ENTERTAINMENT/EDUCATION/MEMBERSHIP/RENT/FITNESS/TELECOM/CLOUD/INSURANCE/LOAN/OTHERS |
| amount | object | Yes | Deduction amount |
| amount.total | string | Yes | Deduction amount (minimum unit) |
| amount.currency | string | Yes | Currency code |
| amount.currencyType | string | Yes | Currency type: FIAT(fiat) / CRYPTO(cryptocurrency) |
| amount.chain | string | No | Chain network (required for cryptocurrency, e.g.: ERC20/TRC20/Arbitrum) |
| amount.chainAddress | string | No | Chain address (required for dynamic on-chain settlement) |
| orderInfo | object | Yes | Order information |
| orderInfo.orderTitle | string | Yes | Order title (displayed to user) |
| orderInfo.orderDesc | string | No | Order description |
| orderInfo.goodsName | string | No | Goods name |
| orderInfo.goodsId | string | No | Goods ID |
| orderInfo.goodsCategory | string | No | Goods category |
| sceneInfo | object | No | Scene information |
| sceneInfo.deviceId | string | No | Device ID |
| sceneInfo.deviceIp | string | No | Device IP |
| sceneInfo.location | object | No | Location information |
| sceneInfo.location.latitude | string | No | Latitude (e.g.: 39.9042) |
| sceneInfo.location.longitude | string | No | Longitude (e.g.: 116.4074) |
| sceneInfo.location.address | string | No | Detailed address |
| notifyUrl | string | Yes | Deduction result async notification URL |
| riskInfo | object | No | Risk control information (optional, for merchant to pass risk-related data) |
| riskInfo.userIp | string | No | User IP address |
| riskInfo.deviceFingerprint | string | No | Device fingerprint |
| riskInfo.userAgent | string | No | User agent string |

#### Response Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| retCode | int | Response code, 20000-success, non-20000-failure |
| retMsg | string | Response message |
| result | object | Response data |
| result.orderNo | string | Platform order number (internal use) |
| result.tradeNo | string | Platform trade number (external display) |
| result.outTradeNo | string | Merchant order number |
| result.status | string | Transaction status: PROCESSING/SUCCESS/FAILED/TIMEOUT |
| result.amount | object | Merchant requested amount (same as request) |
| result.amount.total | string | Amount (minimum unit) |
| result.amount.currency | string | Currency code |
| result.amount.currencyType | string | Currency type: FIAT/CRYPTO |
| result.cryptoPayment | object | User's actual cryptocurrency payment info (returned for fiat orders) |
| result.cryptoPayment.currency | string | Cryptocurrency currency (e.g.: USDT/BTC/ETH) |
| result.cryptoPayment.amount | string | Cryptocurrency amount |
| result.cryptoPayment.chain | string | Chain network (e.g.: TRC20/ERC20) |
| result.cryptoPayment.exchangeRate | string | Exchange rate (1 fiat = ? cryptocurrency) |
| result.cryptoPayment.rateTime | string | Exchange rate lock time |
| result.payTime | string | Payment success time (returned on success) |
| result.failureReason | string | Failure reason (returned on failure) |

#### Request Example (Cryptocurrency Order)

```json
{
  "merchantId": "M123456789",
  "userId": "U_123456789",
  "agreementType": "CYCLE",
  "agreementNo": "AGR202312230001",
  "outTradeNo": "TAXI20231223001",
  "sceneCode": "TAXI",
  "amount": {
    "total": "2350",
    "currency": "USDT",
    "currencyType": "CRYPTO",
    "chain": "TRC20"
  },
  "orderInfo": {
    "orderTitle": "Ride fare",
    "orderDesc": "December 23 trip fare",
    "goodsName": "Express service",
    "goodsId": "TAXI_SERVICE_001",
    "goodsCategory": "Transportation service"
  },
  "sceneInfo": {
    "deviceId": "DEVICE_001",
    "deviceIp": "192.168.1.1"
  },
  "riskInfo": {
    "userIp": "203.0.113.45",
    "deviceFingerprint": "fp_abc123xyz",
    "userAgent": "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0)"
  },
  "notifyUrl": "https://merchant.com/notify/pay"
}
```

#### Request Example (Fiat Currency Order)

```json
{
  "merchantId": "M123456789",
  "userId": "U_123456789",
  "agreementType": "CYCLE",
  "agreementNo": "AGR202312230001",
  "outTradeNo": "TAXI20231223002",
  "sceneCode": "TAXI",
  "amount": {
    "total": "10000",
    "currency": "USD",
    "currencyType": "FIAT"
  },
  "orderInfo": {
    "orderTitle": "Ride fare",
    "orderDesc": "December 23 trip fare"
  },
  "notifyUrl": "https://merchant.com/notify/pay"
}
```

#### Response Example (Cryptocurrency Order)

```json
{
  "retCode": 20000,
  "retMsg": "Success",
  "result": {
    "orderNo": "ORD202312230001",
    "tradeNo": "PAY202312230001",
    "outTradeNo": "TAXI20231223001",
    "status": "SUCCESS",
    "amount": {
      "total": "2350",
      "currency": "USDT",
      "currencyType": "CRYPTO",
      "chain": "TRC20"
    },
    "payTime": "2023-12-23T10:30:00Z"
  }
}
```

#### Response Example (Fiat Order, User Pays with Cryptocurrency)

```json
{
  "retCode": 20000,
  "retMsg": "Success",
  "result": {
    "orderNo": "ORD202312230002",
    "tradeNo": "PAY202312230002",
    "outTradeNo": "TAXI20231223002",
    "status": "SUCCESS",
    "amount": {
      "total": "10000",
      "currency": "USD",
      "currencyType": "FIAT"
    },
    "cryptoPayment": {
      "currency": "USDT",
      "amount": "10005.50",
      "chain": "TRC20",
      "exchangeRate": "1.00055",
      "rateTime": "2023-12-23T10:29:55Z"
    },
    "payTime": "2023-12-23T10:30:00Z"
  }
}
```

#### Response Example (Processing)

```json
{
  "retCode": 20000,
  "retMsg": "Success",
  "result": {
    "orderNo": "ORD202312230003",
    "tradeNo": "PAY202312230003",
    "outTradeNo": "TAXI20231223003",
    "status": "PROCESSING",
    "amount": {
      "total": "5000",
      "currency": "USDT",
      "currencyType": "CRYPTO",
      "chain": "TRC20"
    }
  }
}
```

#### Response Example (Deduction Failed)

```json
{
  "retCode": 20000,
  "retMsg": "Success",
  "result": {
    "orderNo": "ORD202312230004",
    "tradeNo": "PAY202312230004",
    "outTradeNo": "TAXI20231223004",
    "status": "FAILED",
    "amount": {
      "total": "5000",
      "currency": "USDT",
      "currencyType": "CRYPTO",
      "chain": "TRC20"
    },
    "failureReason": "BALANCE_NOT_ENOUGH"
  }
}
```

---

### 3.4 Pay with Sign API (One-Step)

**Request Path**: POST /v5/pay/agreement/pay-with-sign

**Feature Description**: This API supports merchants to complete both agreement signing and deduction payment in a single call. Signing is optional, merchants can choose:
1. **Sign + Pay Mode**: Pass sign parameters, system creates agreement first, then executes deduction immediately after successful signing
2. **Pay Only Mode**: Do not pass sign parameters, only pass existing `agreementNo`, execute deduction directly based on signed agreement

**Applicable Scenarios**:
- First payment scenario: Complete both signing and first payment in one step when user uses the service for the first time
- Quick payment scenario: Simplify merchant integration, reduce API call count

#### Request Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| merchantId | string | Yes | Merchant ID |
| agreementType | string | Yes | Sign type: CYCLE(periodic deduction) / NON_CYCLE(non-periodic deduction) / SINGLE(single authorization) |
| signParams | object | No | Sign parameters (required for first sign + payment) |
| signParams.merchantUserId | string | No | Merchant-side user ID (optional, used for merchant internal user association) |
| signParams.sceneCode | string | Conditional | Scene code (required when passing signParams, see 7.1 Scene Code List) |
| signParams.productCode | string | No | Product code, assigned by platform |
| signParams.externalAgreementNo | string | Conditional | Merchant agreement number (required when passing signParams, unique on merchant side) |
| signParams.signValidTime | string | No | Sign validity period, ISO8601 format |
| signParams.singleLimit | object | No | Single transaction limit configuration |
| signParams.singleLimit.amount | string | Conditional | Limit amount (required when passing singleLimit) |
| signParams.singleLimit.currency | string | Conditional | Currency code (required when passing singleLimit) |
| signParams.singleLimit.currencyType | string | Conditional | Currency type: FIAT/CRYPTO (required when passing singleLimit) |
| signParams.singleLimit.chain | string | No | Chain network (optional for cryptocurrency) |
| signParams.singleLimit.chainAddress | string | No | Chain address (required for dynamic on-chain settlement) |
| signParams.periodLimits | array | No | Period limit configuration list |
| signParams.periodLimits[].periodType | string | Conditional | Period type: DAY/WEEK/MONTH/YEAR (required when passing periodLimits) |
| signParams.periodLimits[].amount | string | Conditional | Period limit amount (required when passing periodLimits) |
| signParams.periodLimits[].currency | string | Conditional | Currency code (required when passing periodLimits) |
| signParams.periodLimits[].currencyType | string | Conditional | Currency type: FIAT/CRYPTO (required when passing periodLimits) |
| signParams.periodLimits[].chain | string | No | Chain network (optional for cryptocurrency) |
| signParams.periodLimits[].chainAddress | string | No | Chain address (required for dynamic on-chain settlement) |
| signParams.signNotifyUrl | string | No | Sign result async notification URL |
| signParams.returnUrl | string | No | Redirect URL after sign completion |
| signParams.signExpireMinutes | int | No | Sign link validity period (minutes), default 30 |
| signParams.extraParams | string | No | Extension parameters (JSON string) |
| payParams | object | Yes | Deduction payment parameters |
| payParams.agreementNo | string | Conditional | Platform agreement number (required when not passing signParams, use existing agreement) |
| payParams.outTradeNo | string | Yes | Merchant order number (unique on merchant side) |
| payParams.sceneCode | string | Yes | Scene code (see 7.1 Scene Code List) |
| payParams.amount | object | Yes | Deduction amount |
| payParams.amount.total | string | Yes | Deduction amount (minimum unit) |
| payParams.amount.currency | string | Yes | Currency code |
| payParams.amount.currencyType | string | Yes | Currency type: FIAT/CRYPTO |
| payParams.amount.chain | string | No | Chain network (required for cryptocurrency) |
| payParams.amount.chainAddress | string | No | Chain address (required for dynamic on-chain settlement) |
| payParams.orderInfo | object | Yes | Order information |
| payParams.orderInfo.orderTitle | string | Yes | Order title |
| payParams.orderInfo.orderDesc | string | No | Order description |
| payParams.orderInfo.goodsName | string | No | Goods name |
| payParams.orderInfo.goodsId | string | No | Goods ID |
| payParams.orderInfo.goodsCategory | string | No | Goods category |
| payParams.sceneInfo | object | No | Scene information |
| payParams.sceneInfo.deviceId | string | No | Device ID |
| payParams.sceneInfo.deviceIp | string | No | Device IP |
| payParams.sceneInfo.location | object | No | Location information |
| payParams.sceneInfo.location.latitude | string | No | Latitude |
| payParams.sceneInfo.location.longitude | string | No | Longitude |
| payParams.sceneInfo.location.address | string | No | Detailed address |
| payParams.payNotifyUrl | string | Yes | Payment result async notification URL |
| payParams.riskInfo | object | No | Risk control information |
| payParams.riskInfo.userIp | string | No | User IP address |
| payParams.riskInfo.deviceFingerprint | string | No | Device fingerprint |
| payParams.riskInfo.userAgent | string | No | User agent string |

#### Response Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| retCode | int | Response code, 20000-success, non-20000-failure |
| retMsg | string | Response message |
| result | object | Response data |
| result.signResult | object | Sign result (if signing was initiated) |
| result.signResult.agreementNo | string | Platform agreement number |
| result.signResult.externalAgreementNo | string | Merchant agreement number |
| result.signResult.signOrderId | string | Platform sign order number |
| result.signResult.status | string | Sign status: INIT/PENDING/SIGNED/FAILED |
| result.signResult.signTime | string | Sign success time (returned on success) |
| result.signResult.validTime | string | Agreement validity period |
| result.signResult.signUrl | string | Sign page URL (for H5 redirect) |
| result.signResult.qrCode | string | Sign QR code content (for user App scan) |
| result.signResult.qrCodeUrl | string | Sign QR code image URL (can be displayed directly) |
| result.signResult.expireTime | string | Sign link/QR code expiration time |
| result.payResult | object | Deduction result |
| result.payResult.tradeNo | string | Platform transaction number |
| result.payResult.outTradeNo | string | Merchant order number |
| result.payResult.status | string | Transaction status: PROCESSING/SUCCESS/FAILED/TIMEOUT |
| result.payResult.amount | object | Merchant requested amount |
| result.payResult.amount.total | string | Amount (minimum unit) |
| result.payResult.amount.currency | string | Currency code |
| result.payResult.amount.currencyType | string | Currency type: FIAT/CRYPTO |
| result.payResult.cryptoPayment | object | User's actual cryptocurrency payment info (returned for fiat order) |
| result.payResult.cryptoPayment.currency | string | Cryptocurrency currency |
| result.payResult.cryptoPayment.amount | string | Cryptocurrency amount |
| result.payResult.cryptoPayment.chain | string | Chain network |
| result.payResult.cryptoPayment.exchangeRate | string | Exchange rate |
| result.payResult.cryptoPayment.rateTime | string | Rate lock time |
| result.payResult.payTime | string | Payment success time (returned on success) |
| result.payResult.failureReason | string | Failure reason (returned on failure) |

#### Request Example 1: Sign + Pay (First Use)

```json
{
  "merchantId": "M123456789",
  "agreementType": "CYCLE",
  "signParams": {
    "merchantUserId": "merchant_user_123",
    "sceneCode": "TAXI",
    "externalAgreementNo": "MERCHANT_AGR_001",
    "signValidTime": "2026-12-23T10:30:00Z",
    "singleLimit": {
      "amount": "100000",
      "currency": "USDT",
      "currencyType": "CRYPTO",
      "chain": "TRC20"
    },
    "periodLimits": [
      {
        "periodType": "DAY",
        "amount": "500000",
        "currency": "USDT",
        "currencyType": "CRYPTO",
        "chain": "TRC20"
      }
    ],
    "signNotifyUrl": "https://merchant.com/notify/sign"
  },
  "payParams": {
    "outTradeNo": "TAXI20231223001",
    "sceneCode": "TAXI",
    "amount": {
      "total": "2350",
      "currency": "USDT",
      "currencyType": "CRYPTO",
      "chain": "TRC20"
    },
    "orderInfo": {
      "orderTitle": "Taxi Fare",
      "orderDesc": "Trip on December 23"
    },
    "payNotifyUrl": "https://merchant.com/notify/pay",
    "riskInfo": {
      "userIp": "203.0.113.45",
      "deviceFingerprint": "fp_abc123xyz"
    }
  }
}
```

#### Response Example 1: Sign + Pay (Sync Response - Waiting for User Scan)

```json
{
  "retCode": 20000,
  "retMsg": "Success",
  "result": {
    "signResult": {
      "agreementNo": null,
      "externalAgreementNo": "MERCHANT_AGR_001",
      "signOrderId": "SIGN202312230001",
      "status": "INIT",
      "signTime": null,
      "validTime": "2026-12-23T10:30:00Z",
      "signUrl": "https://pay.example.com/sign?token=xxx",
      "qrCode": "https://pay.example.com/sign?token=xxx",
      "qrCodeUrl": "https://pay.example.com/qr/SIGN202312230001.png",
      "expireTime": "2023-12-23T11:00:00Z"
    },
    "payResult": {
      "tradeNo": null,
      "outTradeNo": "TAXI20231223001",
      "status": "PENDING",
      "amount": {
        "total": "2350",
        "currency": "USDT",
        "currencyType": "CRYPTO",
        "chain": "TRC20"
      },
      "payTime": null,
      "failureReason": null
    }
  }
}
```

**Notes**:
- `signResult.status = "INIT"` - Sign request created, waiting for user scan
- `payResult.status = "PENDING"` - Payment order created, waiting for sign completion to auto-execute
- Merchant should display `qrCodeUrl` or `signUrl` for user to scan
- Final result returned via Webhook async notification (see examples below)

#### Request Example 2: Pay Only (Using Existing Agreement)

```json
{
  "merchantId": "M123456789",
  "agreementType": "CYCLE",
  "payParams": {
    "agreementNo": "AGR202312230001",
    "outTradeNo": "TAXI20231223002",
    "sceneCode": "TAXI",
    "amount": {
      "total": "3500",
      "currency": "USDT",
      "currencyType": "CRYPTO",
      "chain": "TRC20"
    },
    "orderInfo": {
      "orderTitle": "Taxi Fare",
      "orderDesc": "Second trip on December 23"
    },
    "payNotifyUrl": "https://merchant.com/notify/pay"
  }
}
```

#### Response Example 2: Pay Only (Sync Response - Using Existing Agreement)

```json
{
  "retCode": 20000,
  "retMsg": "Success",
  "result": {
    "signResult": null,
    "payResult": {
      "tradeNo": "PAY202312230002",
      "outTradeNo": "TAXI20231223002",
      "status": "PROCESSING",
      "amount": {
        "total": "3500",
        "currency": "USDT",
        "currencyType": "CRYPTO",
        "chain": "TRC20"
      },
      "payTime": null,
      "failureReason": null
    }
  }
}
```

**Notes**:
- `signResult = null` - No sign initiated, using existing agreement
- `payResult.status = "PROCESSING"` - Deduction payment processing
- Final result returned via Webhook async notification

#### Webhook Async Notification

Sign result and payment result are sent as **independent notifications** to their respective notify URLs:

| Scenario | Sent To | Format |
| --- | --- | --- |
| Sign + Pay success | signNotifyUrl receives sign success; payNotifyUrl receives pay success | Same format as 4.1 and 4.2 |
| User rejected sign | signNotifyUrl receives sign rejected notification | eventType=REJECTED, notifyType=AGREEMENT_STATUS |
| Sign failed (system error) | signNotifyUrl receives sign failed notification | eventType=AGREEMENT_SIGN_RESULT, notifyType=TRANSACTION_RESULT |

**Notification Example 1: Sign Success (sent to signNotifyUrl)**

```json
{
  "notifyId": "NOTIFY202312230001",
  "notifyType": "AGREEMENT_STATUS",
  "notifyTime": "2023-12-23T10:35:05+00:00",
  "merchantId": "M123456789",
  "data": {
    "eventType": "SIGNED",
    "status": "SIGNED",
    "agreementNo": "AGR202312230001",
    "externalAgreementNo": "MERCHANT_AGR_001",
    "agreementType": "CYCLE",
    "userId": "U_123456789",
    "merchantUserId": "merchant_user_123",
    "sceneCode": "TAXI",
    "signTime": "2023-12-23T10:35:00+00:00"
  }
}
```

**Notification Example 2: Pay Success (sent to payNotifyUrl)**

```json
{
  "notifyId": "NOTIFY202312230002",
  "notifyType": "TRANSACTION_RESULT",
  "notifyTime": "2023-12-23T10:35:06+00:00",
  "merchantId": "M123456789",
  "data": {
    "eventType": "PAY",
    "orderType": "PAY",
    "status": "SUCCESS",
    "orderNo": "ORD202312230001",
    "tradeNo": "PAY202312230001",
    "outTradeNo": "TAXI20231223001",
    "agreementNo": "AGR202312230001",
    "amount": {
      "total": "2350",
      "currency": "USDT",
      "currencyType": "CRYPTO"
    },
    "payTime": "2023-12-23T10:35:05+00:00"
  }
}
```

**Notification Example 3: User Rejected (sent to signNotifyUrl)**

```json
{
  "notifyId": "NOTIFY202312230003",
  "notifyType": "AGREEMENT_STATUS",
  "notifyTime": "2023-12-23T10:45:00+00:00",
  "merchantId": "M123456789",
  "data": {
    "eventType": "REJECTED",
    "status": "REJECTED",
    "agreementNo": "AGR202312230003",
    "externalAgreementNo": "MERCHANT_AGR_003",
    "merchantId": "M123456789",
    "failureReason": "User canceled signing"
  }
}
```

**Notification Example 4: Sign Failed - System Error (sent to signNotifyUrl)**

```json
{
  "notifyId": "NOTIFY202312230004",
  "notifyType": "TRANSACTION_RESULT",
  "notifyTime": "2023-12-23T10:45:00+00:00",
  "merchantId": "M123456789",
  "data": {
    "eventType": "AGREEMENT_SIGN_RESULT",
    "status": "FAILED",
    "agreementNo": "AGR202312230004",
    "externalAgreementNo": "MERCHANT_AGR_004",
    "merchantId": "M123456789",
    "failureReason": "Payment confirmation failed: Insufficient balance"
  }
}
```

**Webhook Notification Notes**:
- Sign result notifications sent to `signNotifyUrl`, payment result notifications sent to `payNotifyUrl`
- Signature verification method: refer to Section 5.4
- Merchant should return HTTP 200 + `success` to confirm receipt
- If user rejects sign, only sign rejected notification is sent, deduction will not be executed
- If sign fails (system error), only sign failed notification is sent, deduction will not be executed
- Notification includes `notifyId` for deduplication, merchant should save processed `notifyId`

---

**Important Notes**:

1. **Async Flow**
  - Signing requires user scan confirmation, it's an async flow
  - Sync response returns sign QR code and initial status (`INIT`/`PENDING`)
  - Final result returned via Webhook async notification

2. **Business Flow**
  - ① Call API → Returns sign QR code
  - ② Merchant displays QR code → User scans with App
  - ③ User completes sign → System auto-triggers deduction
  - ④ Webhook notification → Returns sign and payment results

3. **Result Processing**
  - Results returned separately in `signResult` and `payResult`
  - If sign fails, deduction not executed, `payResult` is `null`
  - If sign succeeds, user completes payment in app until success

4. **Webhook Notification Strategy**
  - Sign result and payment result are sent as **independent notifications** to respective notify URLs
  - Sign result (success/rejected/failed) sent to `signNotifyUrl`
  - Payment result (success/failed) sent to `payNotifyUrl`

5. **Idempotency Guarantee**
  - Idempotency guaranteed through `externalAgreementNo` for signing
  - Idempotency guaranteed through `outTradeNo` for payment

6. **Optional Signing**
  - When `signParams` is empty, must pass existing agreement number in `payParams.agreementNo`
  - When using existing agreement, no scan needed, direct deduction execution

---

### 3.5 Deduction Refund API

**Request Path**: POST /v5/pay/agreement/refund

**Description**: Initiate refund for successful deduction transaction, supports full and partial refund

#### Request Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| merchantId | string | Yes | Merchant ID |
| userId | string | Yes | Platform user ID (our platform's user identifier) |
| agreementType | string | Yes | Sign type: CYCLE(periodic deduction) / NON_CYCLE(non-periodic deduction) / SINGLE(single authorization) |
| tradeNo | string | Either | Platform trade number |
| outTradeNo | string | Either | Merchant order number |
| outRefundNo | string | Yes | Merchant refund number (unique on merchant side) |
| refundAmount | object | Yes | Refund amount |
| refundAmount.total | string | Yes | Refund amount (minimum unit) |
| refundAmount.currency | string | Yes | Currency code |
| refundAmount.currencyType | string | Yes | Currency type: FIAT(fiat) / CRYPTO(cryptocurrency) |
| refundAmount.chain | string | No | Chain network (required for cryptocurrency) |
| refundReason | string | No | Refund reason |
| notifyUrl | string | Yes | Refund result async notification URL |

#### Request Example

```json
{
  "merchantId": "M123456789",
  "userId": "U_123456789",
  "agreementType": "CYCLE",
  "tradeNo": "PAY202312230001",
  "outRefundNo": "TAXI_RF20231223001",
  "refundAmount": {
    "total": "2350",
    "currency": "USDT",
    "currencyType": "CRYPTO",
    "chain": "TRC20"
  },
  "refundReason": "User cancelled order",
  "notifyUrl": "https://merchant.com/notify/refund"
}
```

#### Response Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| retCode | int | Response code, 20000-success, non-20000-failure |
| retMsg | string | Response message |
| result | object | Response data |
| result.refundNo | string | Platform refund number |
| result.outRefundNo | string | Merchant refund number |
| result.tradeNo | string | Original trade number |
| result.status | string | Refund status: PROCESSING/SUCCESS/FAILED |
| result.refundAmount | object | Refund amount |
| result.refundTime | string | Refund success time (returned on success) |
| result.failureReason | string | Failure reason (returned on failure) |

#### Response Example (Success)

```json
{
  "retCode": 20000,
  "retMsg": "Success",
  "result": {
    "refundNo": "RF202312230001",
    "outRefundNo": "TAXI_RF20231223001",
    "tradeNo": "PAY202312230001",
    "status": "SUCCESS",
    "refundAmount": {
      "total": "2350",
      "currency": "USDT",
      "currencyType": "CRYPTO",
      "chain": "TRC20"
    },
    "refundTime": "2023-12-23T11:30:00Z"
  }
}
```

#### Response Example (Processing)

```json
{
  "retCode": 20000,
  "retMsg": "Success",
  "result": {
    "refundNo": "RF202312230002",
    "outRefundNo": "TAXI_RF20231223002",
    "tradeNo": "PAY202312230001",
    "status": "PROCESSING",
    "refundAmount": {
      "total": "2350",
      "currency": "USDT",
      "currencyType": "CRYPTO",
      "chain": "TRC20"
    }
  }
}
```

#### Response Example (Failed)

```json
{
  "retCode": 20000,
  "retMsg": "Success",
  "result": {
    "refundNo": "RF202312230003",
    "outRefundNo": "TAXI_RF20231223003",
    "tradeNo": "PAY202312230001",
    "status": "FAILED",
    "refundAmount": {
      "total": "2350",
      "currency": "USDT",
      "currencyType": "CRYPTO",
      "chain": "TRC20"
    },
    "failureReason": "REFUND_AMOUNT_EXCEED"
  }
}
```

---

### 3.6 Sign Status Query API

**Request Path**: GET /v5/pay/agreement/query

#### Request Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| merchantId | string | Yes | Merchant ID |
| agreementNo | string | Either | Platform agreement number |
| externalAgreementNo | string | Either | Merchant agreement number |

#### Request Example

```
GET /v5/pay/agreement/query?merchantId=M123456789&agreementNo=AGR202312230001
```

#### Response Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| retCode | int | Response code, 20000-success, non-20000-failure |
| retMsg | string | Response message |
| result | object | Response data |
| result.agreementNo | string | Platform agreement number |
| result.externalAgreementNo | string | Merchant agreement number |
| result.userId | string | Platform user ID |
| result.merchantUserId | string | Merchant-side user ID |
| result.status | string | Status: INIT/PENDING/SIGNED/SUSPENDED/UNSIGNED/EXPIRED/REJECTED/FAILED/TIMEOUT |
| result.signTime | string | Sign time |
| result.validTime | string | Validity period |
| result.singleLimit | object | Single transaction limit |
| result.periodLimits | array | Period limits list (supports multiple period types) |
| result.usedQuota | object | Used quota |

#### Response Example

```json
{
  "retCode": 20000,
  "retMsg": "Success",
  "result": {
    "agreementNo": "AGR202312230001",
    "externalAgreementNo": "MERCHANT_AGR_001",
    "userId": "U_123456789",
    "merchantUserId": "merchant_user_123",
    "status": "SIGNED",
    "signTime": "2023-12-23T10:30:00Z",
    "validTime": "2024-12-23T10:30:00Z",
    "singleLimit": {
      "amount": "100000",
      "currency": "USDT",
      "currencyType": "CRYPTO",
      "chain": "TRC20"
    },
    "periodLimits": [
      {
        "periodType": "DAY",
        "amount": "500000",
        "currency": "USDT",
        "currencyType": "CRYPTO",
        "chain": "TRC20"
      }
    ],
    "usedQuota": {
      "dayUsed": "50000",
      "currency": "USDT",
      "currencyType": "CRYPTO"
    }
  }
}
```

---

### 3.7 Agreement List Query API

**Request Path**: GET /v5/pay/agreement/list

**Description**: Query agreement list under merchant, supports pagination and status filtering

#### Request Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| merchantId | string | Yes | Merchant ID |
| userId | string | No | Platform user ID (filter agreements for specified user) |
| agreementType | string | No | Sign type: CYCLE/NON_CYCLE/SINGLE (query all if not passed) |
| status | string | No | Agreement status filter: INIT/PENDING/SIGNED/SUSPENDED/UNSIGNED/EXPIRED/FAILED |
| sceneCode | string | No | Scene code filter |
| startTime | string | No | Sign start time (ISO8601 format) |
| endTime | string | No | Sign end time (ISO8601 format) |
| pageNo | int | No | Page number, default 1 |
| pageSize | int | No | Page size, default 20, max 100 |

#### Request Example

```
GET /v5/pay/agreement/list?merchantId=M123456789&status=SIGNED&pageNo=1&pageSize=20
```

#### Response Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| retCode | int | Response code, 20000-success, non-20000-failure |
| result | object | Response data |
| result.total | int | Total record count |
| result.pageNo | int | Current page number |
| result.pageSize | int | Page size |
| result.list | array | Agreement list |
| result.list[].agreementNo | string | Platform agreement number |
| result.list[].externalAgreementNo | string | Merchant agreement number |
| result.list[].userId | string | Platform user ID |
| result.list[].merchantUserId | string | Merchant-side user ID |
| result.list[].agreementType | string | Sign type |
| result.list[].sceneCode | string | Scene code |
| result.list[].status | string | Agreement status |
| result.list[].signTime | string | Sign time |
| result.list[].validTime | string | Validity period |

#### Response Example

```json
{
  "retCode": 20000,
  "retMsg": "Success",
  "result": {
    "total": 100,
    "pageNo": 1,
    "pageSize": 20,
    "list": [
      {
        "agreementNo": "AGR202312230001",
        "externalAgreementNo": "MERCHANT_AGR_001",
        "userId": "U_123456789",
        "merchantUserId": "merchant_user_123",
        "agreementType": "CYCLE",
        "sceneCode": "SUBSCRIPTION",
        "status": "SIGNED",
        "signTime": "2023-12-23T10:30:00Z",
        "validTime": "2024-12-23T10:30:00Z"
      }
    ]
  }
}
```

---

### 3.8 Transaction/Refund Query API (Single)

**Request Path**: GET /v5/pay/agreement/transaction/query

**Description**: Query single deduction transaction or refund record details, distinguished by recordType

#### Request Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| merchantId | string | Yes | Merchant ID |
| userId | string | Yes | Platform user ID (our platform's user identifier) |
| agreementType | string | Yes | Sign type: CYCLE(periodic deduction) / NON_CYCLE(non-periodic deduction) / SINGLE(single authorization) |
| recordType | string | No | Record type: PAY(deduction transaction)/REFUND(refund record), default PAY |
| tradeNo | string | Conditional | Platform trade number (when recordType=PAY, either this or outTradeNo) |
| outTradeNo | string | Conditional | Merchant order number (when recordType=PAY, either this or tradeNo) |
| refundNo | string | Conditional | Platform refund number (when recordType=REFUND, either this or outRefundNo) |
| outRefundNo | string | Conditional | Merchant refund number (when recordType=REFUND, either this or refundNo) |

#### Request Example (Query Deduction Transaction)

```
GET /v5/pay/agreement/transaction/query?merchantId=M123456789&userId=U_123456789&agreementType=CYCLE&recordType=PAY&tradeNo=PAY202312230001
```

#### Request Example (Query Refund Record)

```
GET /v5/pay/agreement/transaction/query?merchantId=M123456789&userId=U_123456789&agreementType=CYCLE&recordType=REFUND&refundNo=RF202312230001
```

#### Response Parameters (Deduction Transaction recordType=PAY)

| Parameter | Type | Description |
| --- | --- | --- |
| retCode | int | Response code, 20000-success, non-20000-failure |
| retMsg | string | Response message |
| result | object | Transaction details |
| result.tradeNo | string | Platform trade number |
| result.outTradeNo | string | Merchant order number |
| result.status | string | Transaction status |
| result.amount | object | Merchant requested amount |
| result.cryptoPayment | object | User's actual cryptocurrency payment info (returned for fiat orders) |
| result.payTime | string | Payment time |
| result.refundAmount | object | Refunded amount |

#### Response Parameters (Refund Record recordType=REFUND)

| Parameter | Type | Description |
| --- | --- | --- |
| retCode | int | Response code, 20000-success, non-20000-failure |
| retMsg | string | Response message |
| result | object | Refund details |
| result.refundNo | string | Platform refund number |
| result.outRefundNo | string | Merchant refund number |
| result.tradeNo | string | Original trade number |
| result.status | string | Refund status: PROCESSING/SUCCESS/FAILED |
| result.refundAmount | object | Refund amount |
| result.refundTime | string | Refund success time |
| result.failureReason | string | Failure reason |

#### Response Example (Deduction Transaction)

```json
{
  "retCode": 20000,
  "retMsg": "Success",
  "result": {
    "tradeNo": "PAY202312230002",
    "outTradeNo": "TAXI20231223002",
    "status": "SUCCESS",
    "amount": {
      "total": "10000",
      "currency": "USD",
      "currencyType": "FIAT"
    },
    "cryptoPayment": {
      "currency": "USDT",
      "amount": "10005.50",
      "chain": "TRC20",
      "exchangeRate": "1.00055",
      "rateTime": "2023-12-23T10:29:55Z"
    },
    "payTime": "2023-12-23T10:30:00Z",
    "refundAmount": {
      "total": "0",
      "currency": "USD",
      "currencyType": "FIAT"
    }
  }
}
```

#### Response Example (Refund Record)

```json
{
  "retCode": 20000,
  "retMsg": "Success",
  "result": {
    "refundNo": "RF202312230001",
    "outRefundNo": "TAXI_RF20231223001",
    "tradeNo": "PAY202312230001",
    "status": "SUCCESS",
    "refundAmount": {
      "total": "2350",
      "currency": "USDT",
      "currencyType": "CRYPTO",
      "chain": "TRC20"
    },
    "refundTime": "2023-12-23T11:30:00Z"
  }
}
```

---

### 3.9 Deduction Transaction List API

**Request Path**: GET /v5/pay/agreement/transaction/list

**Description**: Query deduction transaction or refund record list under an agreement, supports pagination and time range filtering

#### Request Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| merchantId | string | Yes | Merchant ID |
| userId | string | Yes | Platform user ID (our platform's user identifier) |
| agreementType | string | Yes | Sign type: CYCLE(periodic deduction) / NON_CYCLE(non-periodic deduction) / SINGLE(single authorization) |
| agreementNo | string | Yes | Platform agreement number |
| recordType | string | No | Record type: PAY(deduction transaction)/REFUND(refund record), default PAY |
| status | string | No | Status filter: SUCCESS/FAILED/PROCESSING |
| startTime | string | No | Start time (ISO8601 format) |
| endTime | string | No | End time (ISO8601 format) |
| pageNo | int | No | Page number, default 1 |
| pageSize | int | No | Page size, default 20, max 100 |

#### Request Example

```
GET /v5/pay/agreement/transaction/list?merchantId=M123456789&userId=U_123456789&agreementType=CYCLE&agreementNo=AGR202312230001&recordType=PAY&status=SUCCESS&pageNo=1&pageSize=20
```

#### Response Parameters (Deduction Transaction recordType=PAY)

| Parameter | Type | Description |
| --- | --- | --- |
| retCode | int | Response code, 20000-success, non-20000-failure |
| result | object | Response data |
| result.total | int | Total record count |
| result.pageNo | int | Current page number |
| result.pageSize | int | Page size |
| result.list | array | Transaction list |
| result.list[].tradeNo | string | Platform trade number |
| result.list[].outTradeNo | string | Merchant order number |
| result.list[].status | string | Transaction status |
| result.list[].amount | object | Merchant requested amount |
| result.list[].cryptoPayment | object | User's actual cryptocurrency payment info (returned for fiat orders) |
| result.list[].payTime | string | Payment time |
| result.list[].refundAmount | object | Refunded amount |

#### Response Parameters (Refund Record recordType=REFUND)

| Parameter | Type | Description |
| --- | --- | --- |
| retCode | int | Response code, 20000-success, non-20000-failure |
| retMsg | string | Response message |
| result | object | Response data |
| result.total | int | Total record count |
| result.pageNo | int | Current page number |
| result.pageSize | int | Page size |
| result.list | array | Refund list |
| result.list[].refundNo | string | Platform refund number |
| result.list[].outRefundNo | string | Merchant refund number |
| result.list[].tradeNo | string | Original trade number |
| result.list[].status | string | Refund status: PROCESSING/SUCCESS/FAILED |
| result.list[].refundAmount | object | Refund amount |
| result.list[].refundTime | string | Refund success time |
| result.list[].failureReason | string | Failure reason (returned on failure) |

#### Response Example (Deduction Transaction recordType=PAY)

```json
{
  "retCode": 20000,
  "retMsg": "Success",
  "result": {
    "total": 50,
    "pageNo": 1,
    "pageSize": 20,
    "list": [
      {
        "tradeNo": "PAY202312230001",
        "outTradeNo": "TAXI20231223001",
        "status": "SUCCESS",
        "amount": {
          "total": "10000",
          "currency": "USD",
          "currencyType": "FIAT"
        },
        "cryptoPayment": {
          "currency": "USDT",
          "amount": "10005.50",
          "chain": "TRC20",
          "exchangeRate": "1.00055",
          "rateTime": "2023-12-23T10:29:55Z"
        },
        "payTime": "2023-12-23T10:30:00Z",
        "refundAmount": {
          "total": "0",
          "currency": "USD",
          "currencyType": "FIAT"
        }
      }
    ]
  }
}
```

#### Response Example (Refund Record recordType=REFUND)

```json
{
  "retCode": 20000,
  "retMsg": "Success",
  "result": {
    "total": 10,
    "pageNo": 1,
    "pageSize": 20,
    "list": [
      {
        "refundNo": "RF202312230001",
        "outRefundNo": "TAXI_RF20231223001",
        "tradeNo": "PAY202312230001",
        "status": "SUCCESS",
        "refundAmount": {
          "total": "2350",
          "currency": "USDT",
          "currencyType": "CRYPTO",
          "chain": "TRC20"
        },
        "refundTime": "2023-12-23T11:30:00Z"
      }
    ]
  }
}
```

---

## 4. Async Notifications

All Webhook notifications use a unified three-part structure:

### Notification Structure Description

```json
{
  // Part 1: Common fields
  "notifyId": "NOTIFY202312230001",      // Notification unique identifier (for merchant deduplication)
  "notifyType": "AGREEMENT_STATUS",         // Notification type
  "notifyTime": "2023-12-23 10:30:05",    // Notification send time
  "merchantId": "M123456789",              // Merchant ID

  // Part 2: Business data
  "data": {
    // Specific business fields, varies by notifyType
  },

  // Part 3: Signature
  "sign": "Base64 encoded signature",     // Signature value
  "signType": "RSA2"                       // Signature algorithm
}
```

### Common Field Description

| Parameter | Type | Description |
| --- | --- | --- |
| notifyId | string | Notification unique identifier (for merchant deduplication) |
| notifyType | string | Notification type (see enum below) |
| notifyTime | string | Notification send time (ISO8601 format with timezone: yyyy-MM-dd'T'HH:mm:ssXXX, e.g., 2023-12-23T10:30:05+08:00) |
| merchantId | string | Merchant ID |
| data | object | Business data (different structure based on notifyType) |
| sign | string | Signature value (Base64 encoded) |
| signType | string | Signature algorithm, fixed as RSA2 |

### Notification Type Enum

| notifyType | Description | Applicable Scenarios |
| --- | --- | --- |
| AGREEMENT_STATUS | Agreement status result notification | Sign, unsign, suspend, resume, timeout and all agreement status changes |
| TRANSACTION_RESULT | Transaction result notification | Deduction, refund and all transaction results |

**Description**:
- `notifyType` only indicates the category (agreement/transaction)
- Specific event type is distinguished by `data.eventType` field
- Specific result status is distinguished by `data.status` field

### eventType Event Type Enum (Agreement)

| eventType | Description | Corresponding notifyType |
| --- | --- | --- |
| SIGNED | Sign success | AGREEMENT_STATUS |
| REJECTED | Sign rejected (user canceled) | AGREEMENT_STATUS |
| UNSIGNED | Unsign event | AGREEMENT_STATUS |
| SUSPENDED | Suspend event | AGREEMENT_STATUS |
| EXPIRED | Agreement expired | AGREEMENT_STATUS |
| TIMEOUT | Sign timeout | AGREEMENT_STATUS |

### eventType Event Type Enum (Transaction)

| eventType | Description | Corresponding notifyType |
| --- | --- | --- |
| PAY | Deduction event | TRANSACTION_RESULT |
| REFUND | Refund event | TRANSACTION_RESULT |
| AGREEMENT_SIGN_RESULT | Sign failed (system error) | TRANSACTION_RESULT |

---

### 4.1 Sign Result Notification

**Description**: After user scans QR code, completes identity verification and signs successfully, platform pushes sign result notification to merchant

#### data Field Description

| Parameter | Type | Description |
| --- | --- | --- |
| agreementNo | string | Platform agreement number |
| externalAgreementNo | string | Merchant agreement number |
| agreementType | string | Sign type: CYCLE/NON_CYCLE/SINGLE |
| status | string | Sign status: SIGNED/FAILED |
| userId | string | Platform user ID |
| merchantUserId | string | Merchant-side user ID |
| sceneCode | string | Scene code |
| signTime | string | Sign time |
| failureCode | string | Failure error code (returned on failure, 9-digit string) |
| failureReason | string | Failure reason description (returned on failure) |

#### Notification Example (Success)

```json
{
  "notifyId": "NOTIFY202312230001",
  "notifyType": "AGREEMENT_STATUS",
  "notifyTime": "2023-12-23 10:30:05",
  "merchantId": "M123456789",
  "data": {
    "agreementNo": "AGR202312230001",
    "externalAgreementNo": "MERCHANT_AGR_001",
    "agreementType": "CYCLE",
    "eventType": "SIGNED",
    "status": "SIGNED",
    "userId": "U_123456789",
    "merchantUserId": "merchant_user_123",
    "sceneCode": "TAXI",
    "signTime": "2023-12-23 10:30:00"
  },
  "sign": "Base64 encoded signature",
  "signType": "RSA2"
}
```

#### Notification Example (Failure)

```json
{
  "notifyId": "NOTIFY202312230009",
  "notifyType": "AGREEMENT_STATUS",
  "notifyTime": "2023-12-23 10:35:05",
  "merchantId": "M123456789",
  "data": {
    "agreementNo": "AGR202312230002",
    "externalAgreementNo": "MERCHANT_AGR_002",
    "agreementType": "CYCLE",
    "eventType": "FAILED",
    "eventType": "PAY",
    "orderType": "PAY",
    "status": "FAILED",
    "userId": "U_123456789",
    "merchantUserId": "merchant_user_123",
    "sceneCode": "TAXI",
    "failureCode": "139001001",
    "failureReason": "User authentication timeout (downstream code=300100002, msg=User auth timeout)"
  },
  "sign": "Base64 encoded signature",
  "signType": "RSA2"
}
```

### 4.2 Deduction Result Notification

**Description**: After deduction completes, platform pushes deduction result notification to merchant

#### data Field Description

| Parameter | Type | Description |
| --- | --- | --- |
| orderNo | string | Platform order number |
| tradeNo | string | Platform trade number |
| outTradeNo | string | Merchant order number |
| agreementNo | string | Platform agreement number |
| status | string | Transaction status: SUCCESS/FAILED |
| amount | object | Amount object |
| amount.total | string | Amount (minimum unit) |
| amount.currency | string | Currency code |
| amount.currencyType | string | Currency type: FIAT/CRYPTO |
| payTime | string | Payment time |
| failureCode | string | Failure error code (returned on failure, 9-digit string) |
| failureReason | string | Failure reason description (returned on failure) |

#### Notification Example (Success)

```json
{
  "notifyId": "NOTIFY202312230002",
  "notifyType": "TRANSACTION_RESULT",
  "notifyTime": "2023-12-23 10:30:05",
  "merchantId": "M123456789",
  "data": {
    "orderNo": "ORD202312230001",
    "tradeNo": "PAY202312230001",
    "outTradeNo": "TAXI20231223001",
    "agreementNo": "AGR202312230001",
    "eventType": "PAY",
    "orderType": "PAY",
    "status": "SUCCESS",
    "amount": {
      "total": "2350",
      "currency": "USDT",
      "currencyType": "CRYPTO"
    },
    "payTime": "2023-12-23 10:30:00"
  },
  "sign": "Base64 encoded signature",
  "signType": "RSA2"
}
```

#### Notification Example (Deduction Failed)

```json
{
  "notifyId": "NOTIFY202312230004",
  "notifyType": "TRANSACTION_RESULT",
  "notifyTime": "2023-12-23 10:30:05",
  "merchantId": "M123456789",
  "data": {
    "orderNo": "ORD202312230003",
    "tradeNo": "PAY202312230003",
    "outTradeNo": "TAXI20231223003",
    "agreementNo": "AGR202312230001",
    "eventType": "PAY",
    "orderType": "PAY",
    "status": "FAILED",
    "amount": {
      "total": "5000",
      "currency": "USDT",
      "currencyType": "CRYPTO"
    },
    "failureCode": "139002003",
    "failureReason": "Insufficient balance (downstream code=120100006, msg=Balance insufficient)"
  },
  "sign": "Base64 encoded signature",
  "signType": "RSA2"
}
```

### 4.3 Agreement Unsign Notification

**Description**: When user actively unsigns or agreement auto-expires, platform pushes unsign notification to merchant

#### data Field Description

| Parameter | Type | Description |
| --- | --- | --- |
| agreementNo | string | Platform agreement number |
| externalAgreementNo | string | Merchant agreement number |
| status | string | Agreement status: UNSIGNED |
| unsignType | string | Unsign type: USER(user active)/MERCHANT(merchant initiated)/EXPIRED(auto-expired)/SYSTEM(system unsign) |
| unsignTime | string | Unsign time |

#### Notification Example

```json
{
  "notifyId": "NOTIFY202312230010",
  "notifyType": "AGREEMENT_STATUS",
  "notifyTime": "2023-12-23 15:30:05",
  "merchantId": "M123456789",
  "data": {
    "agreementNo": "AGR202312230001",
    "externalAgreementNo": "MERCHANT_AGR_001",
    "eventType": "UNSIGNED",
    "status": "UNSIGNED",
    "unsignType": "USER",
    "unsignTime": "2023-12-23 15:30:00"
  },
  "sign": "Base64 encoded signature",
  "signType": "RSA2"
}
```

### 4.4 Refund Result Notification

**Description**: After refund completes, platform pushes refund result notification to merchant

#### data Field Description

| Parameter | Type | Description |
| --- | --- | --- |
| orderNo | string | Platform order number |
| refundNo | string | Platform refund number |
| outRefundNo | string | Merchant refund number |
| tradeNo | string | Original trade number |
| outTradeNo | string | Original merchant order number |
| agreementNo | string | Platform agreement number |
| status | string | Refund status: SUCCESS/FAILED |
| refundAmount | object | Refund amount object |
| refundAmount.total | string | Refund amount (minimum unit) |
| refundAmount.currency | string | Currency code |
| refundAmount.currencyType | string | Currency type: FIAT/CRYPTO |
| refundTime | string | Refund success time |
| failureCode | string | Failure error code (returned on failure, 9-digit string) |
| failureReason | string | Failure reason description (returned on failure) |

#### Notification Example (Success)

```json
{
  "notifyId": "NOTIFY202312230005",
  "notifyType": "TRANSACTION_RESULT",
  "notifyTime": "2023-12-23 11:30:05",
  "merchantId": "M123456789",
  "data": {
    "orderNo": "ORD202312230005",
    "refundNo": "RF202312230001",
    "outRefundNo": "TAXI_RF20231223001",
    "tradeNo": "PAY202312230001",
    "outTradeNo": "TAXI20231223001",
    "agreementNo": "AGR202312230001",
    "eventType": "PAY",
    "orderType": "PAY",
    "eventType": "REFUND",
    "orderType": "REFUND",
    "status": "SUCCESS",
    "refundAmount": {
      "total": "2350",
      "currency": "USDT",
      "currencyType": "CRYPTO"
    },
    "refundTime": "2023-12-23 11:30:00"
  },
  "sign": "Base64 encoded signature",
  "signType": "RSA2"
}
```

#### Notification Example (Failure)

```json
{
  "notifyId": "NOTIFY202312230008",
  "notifyType": "TRANSACTION_RESULT",
  "notifyTime": "2023-12-23 11:30:05",
  "merchantId": "M123456789",
  "data": {
    "orderNo": "ORD202312230006",
    "refundNo": "RF202312230002",
    "outRefundNo": "TAXI_RF20231223002",
    "tradeNo": "PAY202312230001",
    "outTradeNo": "TAXI20231223001",
    "agreementNo": "AGR202312230001",
    "eventType": "PAY",
    "orderType": "PAY",
    "eventType": "REFUND",
    "orderType": "REFUND",
    "status": "FAILED",
    "refundAmount": {
      "total": "2350",
      "currency": "USDT",
      "currencyType": "CRYPTO"
    },
    "failureCode": "139002003",
    "failureReason": "Insufficient balance (downstream code=120100006, msg=Balance insufficient)"
  },
  "sign": "Base64 encoded signature",
  "signType": "RSA2"
}
```

### 4.5 Agreement Suspend Notification

**Description**: When agreement is suspended due to risk control or abnormality, platform pushes suspend notification to merchant

#### data Field Description

| Parameter | Type | Description |
| --- | --- | --- |
| agreementNo | string | Platform agreement number |
| externalAgreementNo | string | Merchant agreement number |
| status | string | Agreement status: SUSPENDED |
| suspendReason | string | Suspend reason: RISK(risk interception)/ABNORMAL(abnormality detection)/MANUAL(manual intervention) |
| suspendTime | string | Suspend time |

#### Notification Example

```json
{
  "notifyId": "NOTIFY202312230006",
  "notifyType": "AGREEMENT_STATUS",
  "notifyTime": "2023-12-23 16:30:05",
  "merchantId": "M123456789",
  "data": {
    "agreementNo": "AGR202312230001",
    "externalAgreementNo": "MERCHANT_AGR_001",
    "eventType": "SUSPENDED",
    "status": "SUSPENDED",
    "suspendReason": "RISK",
    "suspendTime": "2023-12-23 16:30:00"
  },
  "sign": "Base64 encoded signature",
  "signType": "RSA2"
}
```

### 4.6 Agreement Resume Notification

**Description**: When suspended agreement returns to normal, platform pushes resume notification to merchant

#### data Field Description

| Parameter | Type | Description |
| --- | --- | --- |
| agreementNo | string | Platform agreement number |
| externalAgreementNo | string | Merchant agreement number |
| status | string | Agreement status: SIGNED |
| resumeTime | string | Resume time |

#### Notification Example

```json
{
  "notifyId": "NOTIFY202312230007",
  "notifyType": "AGREEMENT_STATUS",
  "notifyTime": "2023-12-23 18:30:05",
  "merchantId": "M123456789",
  "data": {
    "agreementNo": "AGR202312230001",
    "externalAgreementNo": "MERCHANT_AGR_001",
    "eventType": "SIGNED",
    "status": "SIGNED",
    "resumeTime": "2023-12-23 18:30:00"
  },
  "sign": "Base64 encoded signature",
  "signType": "RSA2"
}
```

### 4.7 Sign Timeout Notification

**Description**: When sign link/QR code expires, platform pushes sign timeout notification to merchant

#### data Field Description

| Parameter | Type | Description |
| --- | --- | --- |
| agreementNo | string | Platform agreement number |
| externalAgreementNo | string | Merchant agreement number |
| agreementType | string | Sign type: CYCLE/NON_CYCLE/SINGLE |
| status | string | Agreement status: TIMEOUT |
| userId | string | Platform user ID |
| merchantUserId | string | Merchant-side user ID |
| sceneCode | string | Scene code |
| timeoutTime | string | Timeout time |

#### Notification Example

```json
{
  "notifyId": "NOTIFY202312230011",
  "notifyType": "AGREEMENT_TIMEOUT",
  "notifyTime": "2023-12-23 11:00:05",
  "merchantId": "M123456789",
  "data": {
    "agreementNo": "AGR202312230003",
    "externalAgreementNo": "MERCHANT_AGR_003",
    "agreementType": "CYCLE",
    "status": "TIMEOUT",
    "userId": "U_123456789",
    "merchantUserId": "merchant_user_123",
    "sceneCode": "TAXI",
    "timeoutTime": "2023-12-23 11:00:00"
  },
  "sign": "Base64 encoded signature",
  "signType": "RSA2"
}
```

### 4.8 Order Timeout Notification

**Description**: When deduction order times out without completion, platform pushes order timeout notification to merchant

#### data Field Description

| Parameter | Type | Description |
| --- | --- | --- |
| orderNo | string | Platform order number |
| tradeNo | string | Platform trade number |
| outTradeNo | string | Merchant order number |
| agreementNo | string | Platform agreement number |
| status | string | Order status: TIMEOUT |
| orderType | string | Order type: PAY/REFUND |
| userId | string | Platform user ID |
| merchantUserId | string | Merchant-side user ID |
| amount | object | Amount object |
| amount.total | string | Amount (minimum unit) |
| amount.currency | string | Currency code |
| amount.currencyType | string | Currency type: FIAT/CRYPTO |
| failureReason | string | Failure reason |
| timeoutTime | string | Timeout time |

#### Notification Example

```json
{
  "notifyId": "NOTIFY202312230012",
  "notifyType": "ORDER_TIMEOUT",
  "notifyTime": "2023-12-23 12:00:05",
  "merchantId": "M123456789",
  "data": {
    "orderNo": "ORD202312230010",
    "tradeNo": "PAY202312230010",
    "outTradeNo": "TAXI20231223010",
    "agreementNo": "AGR202312230001",
    "status": "TIMEOUT",
    "orderType": "PAY",
    "userId": "U_123456789",
    "merchantUserId": "merchant_user_123",
    "amount": {
      "total": "5000",
      "currency": "USDT",
      "currencyType": "CRYPTO"
    },
    "failureReason": "ORDER_TIMEOUT",
    "timeoutTime": "2023-12-23 12:00:00"
  },
  "sign": "Base64 encoded signature",
  "signType": "RSA2"
}
```

---

## Error Code Description (failureCode)

When `status` is `FAILED`, the `data` object contains the following error information fields:

| Field | Type | Description |
| --- | --- | --- |
| failureCode | string | Error code (9-digit string) for programmatic error type identification |
| failureReason | string | Detailed error description, including mapped English description and downstream error info |

### Common Error Codes

| Error Code | English Description | Chinese Description | Applicable Scenarios |
| --- | --- | --- | --- |
| 139002003 | BALANCE_NOT_ENOUGH | Insufficient balance | Payment, Refund |
| 139004005 | AMOUNT_EXCEED_SINGLE_LIMIT | Single transaction limit exceeded | Payment |
| 139004006 | AMOUNT_EXCEED_PERIOD_LIMIT | Period limit exceeded | Payment |
| 139005001 | RISK_REJECT | Rejected by risk control | Sign, Payment, Refund |
| 139004003 | EXCHANGE_RATE_EXPIRED | Exchange rate expired | Payment |
| 139001002 | TRADE_NOT_EXIST | Trade does not exist | Refund |
| 40001 | PARAM_INVALID | Parameter validation failed | All APIs |
| 50002 | DOWNSTREAM_ERROR | Downstream service error | All APIs |

For complete error code list, please refer to the Error Code Documentation.

### failureReason Format

```
{Mapped English Description} (downstream code={Downstream Error Code}, msg={Downstream Error Message})
```

Example:
```
Insufficient balance (downstream code=120100006, msg=Balance insufficient)
```

**Notes**:
- `failureCode` is for programmatic handling - merchants can implement automated error processing
- `failureReason` provides detailed error description including downstream original error info for troubleshooting

---

### 4.9 Webhook General Description

#### Request Headers

| Parameter | Type | Description |
| --- | --- | --- |
| X-Timestamp | string | Notification timestamp (milliseconds), used for signature generation and replay attack prevention |
| X-Signature | string | RSA2 signature value (Base64 encoded), regenerated for each send/retry |
| X-Nonce | string | Random number (5-digit number, range 10000-99999), regenerated for each send/retry |
| X-Sign-Type | string | Signature algorithm, fixed as `RSA2` |
| Content-Type | string | application/json |

**Signature Description**:
- Signature content: `timestamp + nonce + requestBody` (string concatenation, requestBody is pure JSON without sign/signType fields)
- Signature algorithm: RSA2 (SHA256withRSA)
- **Current Implementation**: For compatibility, signature parameters exist in both request headers and request body
  - Request headers: X-Signature, X-Sign-Type, X-Timestamp, X-Nonce
  - Request body: sign, signType fields
  - Merchants can choose to get signature parameters from headers or body for verification

#### Notification Common Fields

All Webhook notifications include the following common fields:

| Parameter | Type | Description |
| --- | --- | --- |
| notifyId | string | Notification unique identifier (for merchant deduplication) |
| notifyType | string | Notification type |
| notifyTime | string | Notification send time (ISO8601 format) |

**Deduplication Note**: Merchant should deduplicate based on `notifyId`, same notifyId notification only needs to be processed once

#### Retry Mechanism

| Configuration | Description |
| --- | --- |
| Retry count | Maximum 5 retries |
| Retry interval | 15s, 30s, 1min, 5min, 30min |
| Success indicator | Merchant returns HTTP 200 with body as plain text `success` (case insensitive) |
| Timeout | Single request timeout 10 seconds (connect/read/write each 10 seconds) |

#### Webhook Request Body Structure

Platform pushes Webhook request body containing business fields and signature fields (for compatibility, signature exists in both headers and body):

| Parameter | Type | Description |
| --- | --- | --- |
| notifyId | string | Notification unique identifier (for merchant deduplication) |
| notifyType | string | Notification type (see enum below) |
| notifyTime | string | Notification send time (ISO8601 format) |
| merchantId | string | Merchant ID |
| data | object | Business data (different structure based on notifyType) |
| signType | string | Signature algorithm type (fixed as RSA2), also exists in X-Sign-Type header |
| sign | string | RSA2 signature value (Base64 encoded), also exists in X-Signature header |

**Important Note**:
- Current implementation: Signature parameters exist in both request body (sign, signType) and HTTP headers (X-Signature, X-Sign-Type)
- Signature parameters are regenerated for each send/retry, ensuring each request has a fresh signature
- Merchant should use `timestamp + nonce + requestBody` (original JSON without sign/signType fields) as verification content
- It is recommended that merchants prioritize getting signature parameters from request headers, signature fields in request body are only for compatibility

#### Notification Type Enum

| notifyType | Description | Applicable Scenarios |
| --- | --- | --- |
| AGREEMENT_STATUS | Agreement status result notification | All agreement status changes including sign, unsign, suspend, resume, timeout |
| TRANSACTION_RESULT | Transaction result notification | All transaction results including deduction and refund |

**Description**:
- `notifyType` only represents category (agreement/transaction)
- Specific event type is distinguished by `data.eventType` field
- Specific result status is distinguished by `data.status` field

### eventType Event Type Enum (Agreement)

| eventType | Description | Corresponding notifyType |
| --- | --- | --- |
| SIGNED | Sign success | AGREEMENT_STATUS |
| REJECTED | Sign rejected (user canceled) | AGREEMENT_STATUS |
| UNSIGNED | Unsign event | AGREEMENT_STATUS |
| SUSPENDED | Suspend event | AGREEMENT_STATUS |
| EXPIRED | Agreement expired | AGREEMENT_STATUS |
| TIMEOUT | Sign timeout | AGREEMENT_STATUS |

### eventType Event Type Enum (Transaction)

| eventType | Description | Corresponding notifyType |
| --- | --- | --- |
| PAY | Deduction event | TRANSACTION_RESULT |
| REFUND | Refund event | TRANSACTION_RESULT |
| AGREEMENT_SIGN_RESULT | Sign failed (system error) | TRANSACTION_RESULT |

#### Merchant Response Format

```
success
```

**Merchant Response**: After receiving notification, return plain text `success` (case insensitive), HTTP status code 200

#### Merchant Processing Code Examples

**Java (Spring Boot)**

```java
@RestController
@RequestMapping("/webhook")
public class WebhookController {

    @Autowired
    private NotifyService notifyService;

    @PostMapping("/agreement")
    public ResponseEntity<String> handleWebhook(
            @RequestHeader("X-Timestamp") String timestamp,
            @RequestHeader("X-Signature") String signature,
            @RequestHeader("X-Nonce") String nonce,
            @RequestHeader("X-Sign-Type") String signType,
            @RequestBody String body) {

        // 1. Verify timestamp (prevent replay attack)
        long ts = Long.parseLong(timestamp);
        if (Math.abs(System.currentTimeMillis() - ts) > 5 * 60 * 1000) {
            log.warn("Webhook timestamp expired");
            return ResponseEntity.status(400).body("timestamp_expired");
        }

        // 2. Verify signature (signature content = timestamp + nonce + requestBody)
        String contentToVerify = timestamp + nonce + body;
        if (!verifySignature(contentToVerify, signature)) {
            log.warn("Webhook signature verification failed");
            return ResponseEntity.status(400).body("signature_error");
        }

        // 3. Parse notification content (request body is pure JSON, no sign/signType fields)
        JSONObject notify = JSON.parseObject(body);
        String notifyId = notify.getString("notifyId");
        String notifyType = notify.getString("notifyType");
        JSONObject data = notify.getJSONObject("data");

        // 4. Idempotency check (deduplicate based on notifyId)
        if (notifyService.isProcessed(notifyId)) {
            log.info("Notification already processed: {}", notifyId);
            return ResponseEntity.ok("success");
        }

        // 5. Process business based on notification type
        try {
            switch (notifyType) {
                case "AGREEMENT_STATUS":
                    notifyService.handleAgreementStatusNotify(data);
                    break;
                case "TRANSACTION_RESULT":
                    notifyService.handleTransactionResultNotify(data);
                    break;
                default:
                    log.warn("Unknown notification type: {}", notifyType);
            }

            // 6. Mark as processed
            notifyService.markAsProcessed(notifyId);
            return ResponseEntity.ok("success");

        } catch (Exception e) {
            log.error("Process notification exception: {}", notifyId, e);
            return ResponseEntity.status(500).body("process_error");
        }
    }

    private boolean verifySignature(String content, String signature) {
        // Use platform public key to verify RSA2 signature (SHA256withRSA)
        return SignatureUtil.verify(content, signature, platformPublicKey);
    }
}
```

**Python (Flask)**

```python
from flask import Flask, request, make_response
import json
import time
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding
import base64

app = Flask(__name__)

# Processed notifyId cache (recommend using Redis in production)
processed_notifies = set()

@app.route('/webhook/agreement', methods=['POST'])
def handle_webhook():
    # 1. Get request headers
    timestamp = request.headers.get('X-Timestamp')
    signature = request.headers.get('X-Signature')
    nonce = request.headers.get('X-Nonce')
    sign_type = request.headers.get('X-Sign-Type')
    body = request.get_data(as_text=True)

    # 2. Verify timestamp (prevent replay attack)
    if abs(int(time.time() * 1000) - int(timestamp)) > 5 * 60 * 1000:
        return make_response("timestamp_expired", 400)

    # 3. Verify signature (signature content = timestamp + nonce + requestBody)
    content_to_verify = timestamp + nonce + body
    if not verify_signature(content_to_verify, signature):
        return make_response("signature_error", 400)

    # 4. Parse notification content (request body is pure JSON, no sign/signType fields)
    notify = json.loads(body)
    notify_id = notify.get('notifyId')
    notify_type = notify.get('notifyType')
    data = notify.get('data', {})

    # 5. Idempotency check
    if notify_id in processed_notifies:
        return make_response("success", 200)

    # 6. Process business
    try:
        if notify_type == 'AGREEMENT_STATUS':
            handle_agreement_status_notify(data)
        elif notify_type == 'TRANSACTION_RESULT':
            handle_transaction_result_notify(data)

        processed_notifies.add(notify_id)
        return make_response("success", 200)

    except Exception as e:
        print(f"Process notification exception: {notify_id}, {str(e)}")
        return make_response("process_error", 500)

def verify_signature(content, signature):
    """Use platform public key to verify RSA2 signature (SHA256withRSA)"""
    try:
        public_key = serialization.load_pem_public_key(PLATFORM_PUBLIC_KEY.encode())
        public_key.verify(
            base64.b64decode(signature),
            content.encode('utf-8'),
            padding.PKCS1v15(),
            hashes.SHA256()
        )
        return True
    except Exception:
        return False
```

**Node.js (Express)**

```javascript
const express = require('express');
const crypto = require('crypto');

const app = express();
app.use(express.json({ verify: (req, res, buf) => { req.rawBody = buf; } }));

// Processed notifyId (recommend using Redis in production)
const processedNotifies = new Set();

app.post('/webhook/agreement', async (req, res) => {
  const timestamp = req.headers['x-timestamp'];
  const signature = req.headers['x-signature'];
  const nonce = req.headers['x-nonce'];
  const signType = req.headers['x-sign-type'];
  const body = req.rawBody.toString();

  // 1. Verify timestamp (prevent replay attack)
  if (Math.abs(Date.now() - parseInt(timestamp)) > 5 * 60 * 1000) {
    return res.status(400).send('timestamp_expired');
  }

  // 2. Verify signature (signature content = timestamp + nonce + requestBody)
  const contentToVerify = timestamp + nonce + body;
  if (!verifySignature(contentToVerify, signature)) {
    return res.status(400).send('signature_error');
  }

  // 3. Parse notification content (request body is pure JSON, no sign/signType fields)
  const notify = JSON.parse(body);
  const { notifyId, notifyType, data } = notify;

  // 4. Idempotency check
  if (processedNotifies.has(notifyId)) {
    return res.status(200).send('success');
  }

  // 5. Process business
  try {
    switch (notifyType) {
      case 'AGREEMENT_STATUS':
        await handleAgreementStatusNotify(data);
        break;
      case 'TRANSACTION_RESULT':
        await handleTransactionResultNotify(data);
        break;
    }

    processedNotifies.add(notifyId);
    return res.status(200).send('success');

  } catch (error) {
    console.error(`Process notification exception: ${notifyId}`, error);
    return res.status(500).send('process_error');
  }
});

function verifySignature(content, signature) {
  // Use platform public key to verify RSA2 signature (SHA256withRSA)
  const verify = crypto.createVerify('RSA-SHA256');
  verify.update(content);
  return verify.verify(PLATFORM_PUBLIC_KEY, signature, 'base64');
}
```

---

## 5. Security Mechanism

### 5.1 Sign Security

| Security Item | Description |
| --- | --- |
| Strong Authentication | First-time sign must pass strong authentication methods like SMS/Face/Password |
| Sign Confirmation Page | User must confirm authorization content on platform page (merchant name, limits, validity period) |
| Sign Validity Period | Supports setting sign validity period, auto-expires when reached |

### 5.2 Deduction Security

| Security Item | Description | Verification Party |
| --- | --- | --- |
| Single Limit | Each deduction does not exceed the single limit agreed at sign time | Transaction Service |
| Period Limit | Daily/Weekly/Monthly cumulative deduction does not exceed period limit | Transaction Service |
| Balance Check | Whether user account balance is sufficient | Transaction Service |
| Agreement Validity | Whether agreement status is SIGNED | Order Service |
| Scene Code Recording | Record deduction scene code for risk analysis (no strict consistency check) | Order Service |
| Merchant Whitelist | Only merchants that passed qualification review can access | Gateway |
| Risk Interception | Real-time risk control: device fingerprint, location anomaly, behavior analysis | Transaction Service |
| Deduction Notification | Real-time notification to user for each deduction (Push/SMS) | Transaction Service |

**Note**: Quota verification (single limit, period limit, balance check) is handled by downstream transaction service (bitpay-transaction-service).

### 5.3 API Security

| Security Item | Description |
| --- | --- |
| HTTPS | All APIs enforce HTTPS |
| Signature Verification | RSA2048 signature (RSA-SHA256 with 2048-bit key) |
| Timestamp Check | Request timestamp and server time difference not exceeding 5 minutes |
| Idempotency Control | Prevent duplicate deductions based on business unique indexes |
| IP Whitelist | Merchant server IP whitelist |

### 5.4 Signature Algorithm Detailed Description

#### Signature Algorithm

| Algorithm | Description |
| --- | --- |
| RSA2 | RSA-SHA256 with 2048-bit key (signType=RSA2) |

**Note**:
- This system only supports RSA2 signature algorithm (SHA256withRSA), does not support HMAC-SHA256
- signType is fixed as `RSA2`
- Private key supports both PKCS1 and PKCS8 PEM formats:
  - PKCS1 format: `-----BEGIN RSA PRIVATE KEY-----`
  - PKCS8 format: `-----BEGIN PRIVATE KEY-----`

#### RSA2048 Signature Flow

**1. Construct String to Sign**

```
String to sign = HTTP Method + "\n" + Request Path + "\n" + Timestamp + "\n" + Request Body
```

**Example**:
```
POST
/v5/pay/agreement/deduction
1703318400000
{"merchantId":"M123456789","userId":"U_123456789",...}
```

**2. Signature Calculation**

```
Signature = Base64(RSA_SHA256_Sign(String to sign, Merchant Private Key))
```

**3. Request Header Settings**

```
X-Timestamp: 1703318400000
X-Signature: Base64 encoded signature value
X-Request-Id: Unique request identifier
Authorization: Bearer {access_token}
```

**4. Code Example (Java)**

Supports both PKCS1 and PKCS8 private key formats:

```java
import java.security.*;
import java.security.spec.PKCS8EncodedKeySpec;
import java.util.Base64;
import org.bouncycastle.openssl.PEMKeyPair;
import org.bouncycastle.openssl.PEMParser;
import org.bouncycastle.openssl.jcajce.JcaPEMKeyConverter;

public class SignatureUtil {

    /**
     * RSA2 Signature (SHA256withRSA)
     * @param content Content to sign
     * @param privateKeyStr Private key (PEM format, supports PKCS1 and PKCS8)
     * @return Base64 encoded signature
     */
    public static String sign(String content, String privateKeyStr) throws Exception {
        PrivateKey privateKey = loadPrivateKey(privateKeyStr);
        Signature signature = Signature.getInstance("SHA256withRSA");
        signature.initSign(privateKey);
        signature.update(content.getBytes("UTF-8"));
        return Base64.getEncoder().encodeToString(signature.sign());
    }

    /**
     * Load private key (auto-detect PKCS1 and PKCS8 formats)
     */
    private static PrivateKey loadPrivateKey(String privateKeyStr) throws Exception {
        // PKCS8 format: -----BEGIN PRIVATE KEY-----
        if (privateKeyStr.contains("BEGIN PRIVATE KEY")) {
            String keyContent = privateKeyStr
                    .replace("-----BEGIN PRIVATE KEY-----", "")
                    .replace("-----END PRIVATE KEY-----", "")
                    .replaceAll("\\s+", "");
            byte[] keyBytes = Base64.getDecoder().decode(keyContent);
            PKCS8EncodedKeySpec keySpec = new PKCS8EncodedKeySpec(keyBytes);
            KeyFactory keyFactory = KeyFactory.getInstance("RSA");
            return keyFactory.generatePrivate(keySpec);
        }
        // PKCS1 format: -----BEGIN RSA PRIVATE KEY----- (requires BouncyCastle)
        else if (privateKeyStr.contains("BEGIN RSA PRIVATE KEY")) {
            PEMParser pemParser = new PEMParser(new java.io.StringReader(privateKeyStr));
            Object object = pemParser.readObject();
            pemParser.close();
            JcaPEMKeyConverter converter = new JcaPEMKeyConverter();
            if (object instanceof PEMKeyPair) {
                return converter.getPrivateKey(((PEMKeyPair) object).getPrivateKeyInfo());
            }
            throw new IllegalArgumentException("Invalid PKCS1 private key");
        }
        throw new IllegalArgumentException("Unsupported private key format");
    }

    /**
     * Construct request signature
     */
    public static String signRequest(String method, String path,
                                      long timestamp, String body,
                                      String privateKeyStr) throws Exception {
        String content = method + "\n" + path + "\n" + timestamp + "\n" + body;
        return sign(content, privateKeyStr);
    }
}
```

**Maven Dependency (BouncyCastle, for PKCS1 format support)**:

```xml
<dependency>
    <groupId>org.bouncycastle</groupId>
    <artifactId>bcpkix-jdk15on</artifactId>
    <version>1.70</version>
</dependency>
```

**5. Code Example (Python)**

```python
import base64
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.asymmetric import padding

def sign(method, path, timestamp, body, private_key):
    content = f"{method}\n{path}\n{timestamp}\n{body}"
    signature = private_key.sign(
        content.encode('utf-8'),
        padding.PKCS1v15(),
        hashes.SHA256()
    )
    return base64.b64encode(signature).decode('utf-8')
```

#### cURL Request Example

The following example shows how to initiate a signed request using cURL (using agreement deduction as example):

**Shell Script (RSA2048 Signature)**

```bash
#!/bin/bash

# Configuration parameters
API_HOST="https://api.bybit.com"
API_PATH="/v5/pay/agreement/deduction"
MERCHANT_PRIVATE_KEY="./merchant_private_key.pem"
ACCESS_TOKEN="your_access_token"

# Request body
REQUEST_BODY='{
  "merchantId": "M123456789",
  "userId": "U_123456789",
  "agreementType": "CYCLE",
  "agreementNo": "AGR202312230001",
  "outTradeNo": "TAXI20231224001",
  "sceneCode": "TAXI",
  "amount": {
    "total": "2350",
    "currency": "USDT",
    "currencyType": "CRYPTO",
    "chain": "TRC20"
  },
  "orderInfo": {
    "orderTitle": "Ride fare"
  },
  "notifyUrl": "https://merchant.com/notify/pay"
}'

# Generate timestamp and request ID
TIMESTAMP=$(date +%s000)
REQUEST_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')

# Construct string to sign
SIGN_CONTENT="POST
${API_PATH}
${TIMESTAMP}
${REQUEST_BODY}"

# Calculate RSA signature
SIGNATURE=$(echo -n "$SIGN_CONTENT" | openssl dgst -sha256 -sign "$MERCHANT_PRIVATE_KEY" | base64 | tr -d '\n')

# Initiate request
curl -X POST "${API_HOST}${API_PATH}" \
  -H "Content-Type: application/json" \
  -H "X-Request-Id: ${REQUEST_ID}" \
  -H "X-Timestamp: ${TIMESTAMP}" \
  -H "X-Signature: ${SIGNATURE}" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -d "${REQUEST_BODY}"
```

**Response Example**

```json
{
  "retCode": 20000,
  "retMsg": "Success",
  "result": {
    "tradeNo": "PAY202312240001",
    "outTradeNo": "TAXI20231224001",
    "status": "PROCESSING",
    "amount": {
      "total": "2350",
      "currency": "USDT",
      "currencyType": "CRYPTO",
      "chain": "TRC20"
    }
  }
}
```

#### Webhook Signature Verification

Merchant needs to verify signature after receiving Webhook notification to prevent forged requests.

**Verification Steps**:

1. Get signature-related parameters from HTTP request headers: `X-Timestamp`, `X-Signature`, `X-Nonce`, `X-Sign-Type`
2. Verify timestamp: Check if `X-Timestamp` is within 5 minutes of current server time (prevent replay attack)
3. Construct content to verify: `timestamp + nonce + requestBody` (string concatenation, not JSON format)
4. Request body is pure JSON: Contains only business fields (notifyId, notifyType, notifyTime, merchantId, data), no signature fields need to be removed
5. Use platform public key to verify signature (RSA2/SHA256withRSA)

**Code Example (Java)**:

```java
import java.security.*;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;

public class WebhookVerifier {

    /**
     * Verify Webhook signature
     * @param body Original request body JSON string (pure JSON, only business fields)
     * @param timestamp X-Timestamp from request header
     * @param nonce X-Nonce from request header
     * @param signature X-Signature from request header
     * @param platformPublicKey Platform public key (PEM format)
     */
    public boolean verifyWebhook(String body, String timestamp, String nonce,
                                  String signature, String platformPublicKey) throws Exception {
        // 1. Check timestamp (prevent replay attack)
        long now = System.currentTimeMillis();
        long ts = Long.parseLong(timestamp);
        if (Math.abs(now - ts) > 5 * 60 * 1000) {
            return false; // Timestamp expired
        }

        // 2. Construct content to verify: timestamp + nonce + requestBody
        String contentToVerify = timestamp + nonce + body;

        // 3. Use platform public key to verify RSA2 signature (SHA256withRSA)
        return verifyRSA2(contentToVerify, signature, platformPublicKey);
    }

    /**
     * RSA2 Signature Verification (SHA256withRSA)
     */
    private boolean verifyRSA2(String content, String signBase64,
                                String publicKeyStr) throws Exception {
        // Handle PEM format public key
        String keyContent = publicKeyStr
                .replace("-----BEGIN PUBLIC KEY-----", "")
                .replace("-----END PUBLIC KEY-----", "")
                .replaceAll("\\s+", "");

        byte[] keyBytes = Base64.getDecoder().decode(keyContent);
        X509EncodedKeySpec keySpec = new X509EncodedKeySpec(keyBytes);
        KeyFactory keyFactory = KeyFactory.getInstance("RSA");
        PublicKey publicKey = keyFactory.generatePublic(keySpec);

        Signature signature = Signature.getInstance("SHA256withRSA");
        signature.initVerify(publicKey);
        signature.update(content.getBytes("UTF-8"));
        return signature.verify(Base64.getDecoder().decode(signBase64));
    }
}
```

#### Key Management

| Key Type | Purpose | Custodian | Format |
| --- | --- | --- | --- |
| Merchant Private Key | Merchant request signature (RSA2) | Merchant (strictly confidential) | PEM (PKCS1 or PKCS8) |
| Merchant Public Key | Platform verifies merchant requests | Platform | PEM (X.509) |
| Platform Private Key | Webhook notification signature (RSA2) | Platform | PEM |
| Platform Public Key | Merchant verifies Webhook | Merchant | PEM (X.509) |

**Private Key Format Description**:

System supports two PEM format private keys:

```
# PKCS1 format (traditional RSA format)
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEA...(Base64 encoded content)
-----END RSA PRIVATE KEY-----

# PKCS8 format (PKCS#8 standard format)
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkq...(Base64 encoded content)
-----END PRIVATE KEY-----
```

**Key Security Requirements**:
1. Private keys must be stored encrypted, plaintext storage is prohibited
2. Rotate keys periodically (recommended at least once per year)
3. Contact platform immediately to replace keys if leaked
4. Test environment and production environment should use different keys
5. PKCS8 format is recommended (more universal), if using PKCS1 format, BouncyCastle library is required

---

## 6. Error Codes

**Note**: Error codes are numeric type, returned through `retCode` field in response body. `retMsg` field returns English error description.

### 6.0 Common Success

| Error Code | Error Identifier | English Description (retMsg) | Chinese Description | Handling Suggestion |
| --- | --- | --- | --- | --- |
| 20000 | SUCCESS | Success | Success | Request processed successfully |

### 6.1 Common Error Codes

| Error Code | Error Identifier | English Description (retMsg) | Chinese Description | Handling Suggestion |
| --- | --- | --- | --- | --- |
| 40000 | PARAM_VALID_ERROR | Parameter validation failed | Parameter validation failed | Check request parameter format and required fields |
| 40001 | UNAUTHORIZED | Unauthorized | Unauthorized | Check if Authorization header is correct |
| 40002 | FORBIDDEN | Access forbidden | Access forbidden | Check IP whitelist or API permission |
| 40003 | NOT_FOUND | Resource not found | Resource not found | Check if request path is correct |
| 40004 | DUPLICATE_REQUEST | Duplicate request | Duplicate request | Use query API to get existing result |

### 6.2 Agreement Related Error Codes

| Error Code | Error Identifier | English Description (retMsg) | Chinese Description | Handling Suggestion |
| --- | --- | --- | --- | --- |
| 139001001 | AGREEMENT_NOT_EXIST | Agreement does not exist | Agreement does not exist | Check agreement number or guide user to re-sign |
| 139001002 | AGREEMENT_EXPIRED | Agreement has expired | Agreement has expired | Guide user to re-sign |
| 139001003 | AGREEMENT_UNSIGNED | Agreement has been unsigned | Agreement has been unsigned | Guide user to re-sign |
| 139001004 | AGREEMENT_SUSPENDED | Agreement is suspended | Agreement is suspended | Wait for agreement resume or contact platform |
| 139001005 | AGREEMENT_STATUS_INVALID | Invalid agreement status | Invalid agreement status | Check if current agreement status supports this operation |
| 139001006 | AGREEMENT_TEMPLATE_NOT_EXIST | Agreement template does not exist | Agreement template does not exist | Contact platform to confirm agreement template configuration |
| 139001007 | AGREEMENT_ALREADY_SIGNED | Agreement already signed | Agreement already signed | No need to re-sign, can directly initiate deduction |
| 139001008 | SCENE_CODE_MISMATCH | Scene code mismatch | Scene code mismatch (deprecated, no longer verified) | This error code is deprecated, scene code no longer strictly verified during deduction |
| 139001009 | MERCHANT_ID_MISMATCH | Merchant ID mismatch | Merchant ID mismatch | Check if merchant ID matches the one used at sign time |
| 139001010 | USER_ID_MISMATCH | User ID mismatch | User ID mismatch | Check if user ID matches the one used at sign time |
| 139001011 | AGREEMENT_USER_MISMATCH | Agreement user mismatch | Agreement user mismatch | Check binding relationship between user and agreement |
| 139001012 | SIGN_URL_EXPIRED | Sign URL has expired | Sign URL has expired | Re-initiate sign request to get new link |
| 139001013 | AGREEMENT_TYPE_MISMATCH | Agreement type mismatch | Agreement type mismatch | Check if agreement type (CYCLE/NON_CYCLE/SINGLE) is correct |

### 6.3 Transaction Related Error Codes

| Error Code | Error Identifier | English Description (retMsg) | Chinese Description | Handling Suggestion |
| --- | --- | --- | --- | --- |
| 139002001 | TRADE_NOT_EXIST | Trade does not exist | Trade does not exist | Check if trade number is correct |
| 139002002 | QUOTA_EXCEEDED | Quota exceeded | Quota exceeded | Notify user of insufficient quota, wait for quota reset or guide to active payment |
| 139002003 | BALANCE_NOT_ENOUGH | Insufficient balance | Insufficient balance | Notify user to top up |
| 139002004 | TRADE_STATUS_INVALID | Invalid trade status | Invalid trade status | Check if current trade status supports this operation |
| 139002005 | TRADE_PROCESSING | Trade is processing | Trade is processing | Wait for trade to complete, do not initiate again |

### 6.4 Refund Related Error Codes

| Error Code | Error Identifier | English Description (retMsg) | Chinese Description | Handling Suggestion |
| --- | --- | --- | --- | --- |
| 139003001 | REFUND_AMOUNT_EXCEED | Refund amount exceeds refundable amount | Refund amount exceeds refundable amount | Check refunded amount, ensure refund amount does not exceed refundable balance |
| 139003002 | REFUND_NOT_ALLOW | Refund not allowed | Refund not allowed | Trade status does not support refund (e.g., trade not successful) |
| 139003003 | REFUND_PROCESSING | Refund is processing | Refund is processing | Do not initiate refund again, wait for refund to complete |
| 139003004 | REFUND_NOT_EXIST | Refund does not exist | Refund does not exist | Check if refund number is correct |

### 6.5 Currency/Amount Related Error Codes

| Error Code | Error Identifier | English Description (retMsg) | Chinese Description | Handling Suggestion |
| --- | --- | --- | --- | --- |
| 139004001 | CHAIN_NOT_SUPPORTED | Chain network not supported | Chain network not supported | Check if chain network is in supported list |
| 139004002 | CURRENCY_NOT_SUPPORTED | Currency not supported | Currency not supported | Check if currency is in supported list |
| 139004003 | EXCHANGE_RATE_EXPIRED | Exchange rate has expired | Exchange rate has expired | Re-get exchange rate before initiating request |
| 139004004 | INVALID_AMOUNT | Invalid amount | Invalid amount | Check if amount format and precision meet requirements |
| 139004005 | AMOUNT_EXCEED_SINGLE_LIMIT | Amount exceeds single transaction limit | Amount exceeds single transaction limit | Lower single deduction amount or adjust agreement limit configuration |
| 139004006 | AMOUNT_EXCEED_PERIOD_LIMIT | Amount exceeds period limit | Amount exceeds period limit | Wait for period reset or adjust agreement limit configuration |
| 139004007 | USER_LIMIT_EXCEED_MERCHANT | User limit exceeds merchant limit | User limit exceeds merchant limit | User custom limit cannot exceed agreement template limit |
| 139004008 | EXCEED_MERCHANT_QUOTA_LIMIT | Exceed merchant quota limit | Exceed merchant quota limit | Contact merchant to adjust quota configuration |

### 6.6 Security/Authentication Related Error Codes

| Error Code | Error Identifier | English Description (retMsg) | Chinese Description | Handling Suggestion |
| --- | --- | --- | --- | --- |
| 139005001 | RISK_REJECT | Rejected by risk control | Rejected by risk control | Guide user to active payment and complete identity verification |
| 139005002 | INVALID_SIGNATURE | Invalid signature | Invalid signature | Check if signature algorithm and key are correct |
| 139005003 | INVALID_TIMESTAMP | Invalid timestamp | Invalid timestamp | Request timestamp differs from server time by more than 5 minutes |
| 139005004 | KEY_NOT_FOUND | Key not found | Key not found | Contact platform to confirm key configuration |

### 6.7 Merchant/User Related Error Codes

| Error Code | Error Identifier | English Description (retMsg) | Chinese Description | Handling Suggestion |
| --- | --- | --- | --- | --- |
| 139006001 | MERCHANT_NOT_EXIST | Merchant does not exist | Merchant does not exist | Check if merchant ID is correct |
| 139006002 | USER_NOT_EXIST | User does not exist | User does not exist | Check if user ID is correct |
| 139006003 | USER_NOT_LOGIN | User not logged in | User not logged in | Require user to log in |
| 139006004 | MERCHANT_SETTLEMENT_CONFIG_ERROR | Merchant settlement configuration error | Merchant settlement configuration error | Contact platform to check merchant settlement configuration |

### 6.8 Order Related Error Codes

| Error Code | Error Identifier | English Description (retMsg) | Chinese Description | Handling Suggestion |
| --- | --- | --- | --- | --- |
| 139007001 | ORDER_NOT_EXIST | Order does not exist | Order does not exist | Check if order number is correct |
| 139007002 | ORDER_USER_MISMATCH | Order user mismatch | Order user mismatch | Check the association between user and order |
| 139007003 | ORDER_STATUS_INVALID | Invalid order status | Invalid order status | Check if current order status supports this operation |

### 6.9 System Error Codes

| Error Code | Error Identifier | English Description (retMsg) | Chinese Description | Handling Suggestion |
| --- | --- | --- | --- | --- |
| 50000 | SYSTEM_ERROR | System error | System error | Please retry later or contact technical support |
| 50001 | SERVICE_UNAVAILABLE | Service unavailable | Service unavailable | System under maintenance, please retry later |
| 50002 | DOWNSTREAM_ERROR | Downstream service error | Downstream service error | Please retry later or contact technical support |

### 6.10 Downstream Error Code Mapping

**Description**: The system maps downstream transaction-service error codes to system error codes, while preserving original error information in the `failureReason` field for troubleshooting.

#### Error Information Format

The error information in the response contains two parts:
- `retCode`: System error code (numeric type)
- `retMsg`: Detailed error message, format: `{System error description} (downstream code={downstream error code}, msg={downstream error message})`

**Example**:
```json
{
  "retCode": 139002003,
  "retMsg": "Insufficient balance (downstream code=120100006, msg=可用余额不足)",
  "result": null
}
```

#### Common Downstream Error Code Mapping Table

| Downstream Code | Downstream Description | System Error Code | System Error Identifier | Handling Suggestion |
|----------|------------|------------|--------------|---------|
| 120100006 | Insufficient balance | 139002003 | BALANCE_NOT_ENOUGH | Prompt user to top up |
| 300200071 | Single transaction limit exceeded | 139004005 | AMOUNT_EXCEED_SINGLE_LIMIT | Reduce transaction amount |
| 300200038 | Security limit exceeded | 139005001 | RISK_REJECT | Guide user to active payment |
| 120100031 | Quote expired | 139004003 | EXCHANGE_RATE_EXPIRED | Retrieve exchange rate again |
| 300xxx series | Risk control errors | 139005001 | RISK_REJECT | Guide user to active payment and identity verification |
| Others | Unknown errors | 50002 | DOWNSTREAM_ERROR | Contact technical support with complete error information |

**Important Notes**:
1. Merchants should handle business based on system error code (retCode) first
2. Downstream error information is for troubleshooting and logging only
3. For unmapped downstream error codes, please contact technical support

---

## 7. Appendix

### 7.1 Scene Code List

Scene codes are defined with reference to bank MCC (Merchant Category Code) industry categories, MCC codes are categorized by first digit.

#### MCC Industry Category Description

| MCC Range | Industry Category | Description |
| --- | --- | --- |
| 3xxx | Travel & Accommodation | Airlines, hotels, car rental |
| 4xxx | Transportation & Utilities | Transportation, telecommunications, utilities |
| 5xxx | Retail & Consumer | Retail stores, food & beverage, gas stations |
| 6xxx | Financial Services | Banks, insurance, loans |
| 7xxx | Business Services | Entertainment, auto services, professional services |
| 8xxx | Professional Organizations | Healthcare, education, membership organizations |

#### Scene Code Definition

| Scene Code | MCC Industry | MCC Example | Description | Typical Scenarios |
| --- | --- | --- | --- | --- |
| **4xxx Transportation & Utilities** |||||
| TAXI | 4xxx | 4121 | Taxi/Ride-hailing | Didi, Uber, ride-hailing |
| TRANSIT | 4xxx | 4111-4131 | Public Transportation | Subway, bus, light rail, train |
| TOLL | 4xxx | 4784 | Toll Fees | ETC, highway fees, bridge/tunnel fees |
| UTILITY | 4xxx | 4900 | Utilities | Electricity, water, gas bills |
| TELECOM | 4xxx | 4814 | Telecom Services | Phone bills, broadband, data packages |
| **5xxx Retail & Food** |||||
| FOOD | 5xxx | 5812-5814 | Food & Beverage Services | Food delivery subscription, restaurant membership |
| SUBSCRIPTION | 5xxx | 5968 | Subscription Services | Content subscription, recurring delivery |
| **6xxx Financial Services** |||||
| INSURANCE | 6xxx | 6300 | Insurance Services | Auto insurance, health insurance, accident insurance |
| LOAN | 6xxx | 6012 | Loan Repayment | Credit card payment, installment payment |
| **7xxx Business Services** |||||
| PARKING | 7xxx | 7523 | Parking Services | Parking lots, street parking |
| RENT | 7xxx | 7512 | Rental Services | Car rental, bike sharing |
| ENTERTAINMENT | 7xxx | 7832-7841 | Entertainment Services | Video membership, music subscription, gaming |
| FITNESS | 7xxx | 7941-7997 | Fitness & Sports | Gyms, sports apps |
| CLOUD | 7xxx | 7372 | Cloud Computing Services | Cloud servers, storage, SaaS |
| **8xxx Professional Services & Membership Organizations** |||||
| EDUCATION | 8xxx | 8211-8299 | Education & Training | Online courses, training institutions |
| MEMBERSHIP | 8xxx | 8398-8699 | Membership Organizations | Clubs, VIP membership |
| **Fallback** |||||
| OTHERS | - | - | Other Scenarios | Other business scenarios that cannot be categorized |

**Notes**:
- MCC (Merchant Category Code) is a standard merchant classification code in banking industry, 4 digits
- Scene codes are categorized by MCC industry category (first digit), convenient for risk control policies and limit management
- If merchant business cannot match the above scene codes, `OTHERS` can be used as fallback
- Selecting correct scene code helps optimize risk control models and user experience

### 7.2 Currency List

#### Fiat Currency (Fiat)

| Currency Code | Description | Standard |
| --- | --- | --- |
| CNY | Chinese Yuan | ISO 4217 |
| USD | US Dollar | ISO 4217 |
| EUR | Euro | ISO 4217 |
| GBP | British Pound | ISO 4217 |
| JPY | Japanese Yen | ISO 4217 |
| KRW | Korean Won | ISO 4217 |
| SGD | Singapore Dollar | ISO 4217 |
| HKD | Hong Kong Dollar | ISO 4217 |
| AUD | Australian Dollar | ISO 4217 |
| CAD | Canadian Dollar | ISO 4217 |

#### Cryptocurrency (Crypto)

| Currency Code | Description | Network |
| --- | --- | --- |
| USDT | Tether | ERC20/TRC20/Arbitrum/Optimism |
| USDC | USD Coin | ERC20/TRC20/Arbitrum/Optimism |
| BTC | Bitcoin | Bitcoin |
| ETH | Ethereum | Ethereum |
| BNB | Binance Coin | BSC |
| SOL | Solana | Solana |
| XRP | Ripple | Ripple |
| DOGE | Dogecoin | Dogecoin |
| TRX | Tron | Tron |
| MATIC | Polygon | Polygon |
| ARB | Arbitrum | Arbitrum |
| OP | Optimism | Optimism |

#### Currency Type Enum

| Type Code | Description |
| --- | --- |
| FIAT | Fiat Currency |
| CRYPTO | Cryptocurrency |

### 7.3 Chain Network List

| Chain Network Code | Description | Supported Currencies |
| --- | --- | --- |
| ERC20 | Ethereum Network | USDT, USDC, ETH |
| TRC20 | Tron Network | USDT, USDC, TRX |
| Arbitrum | Arbitrum L2 Network | USDT, USDC, ARB, ETH |
| Optimism | Optimism L2 Network | USDT, USDC, OP, ETH |
| BSC | Binance Smart Chain | BNB, USDT, USDC |
| Polygon | Polygon Network | MATIC, USDT, USDC |
| Solana | Solana Network | SOL, USDT, USDC |
| Bitcoin | Bitcoin Network | BTC |
| Tron | Tron Native Network | TRX |
| Ripple | Ripple Network | XRP |
| Dogecoin | Dogecoin Network | DOGE |

**Notes**:
- When initiating transaction, `chain` field needs to match `currency`
- Same currency has different address formats on different chains, please ensure correct chain network is used
- Chain network support scope may expand with platform upgrades

### 7.4 Amount Precision Description

#### General Rules

- All amounts are transmitted as string type to avoid floating-point precision loss
- Amount values are integer representation of minimum units (no decimal point)

#### Fiat Currency Precision

| Currency | Minimum Unit | Precision Description | Example |
| --- | --- | --- | --- |
| USD | cent | 2 decimals | "10000" = 100.00 USD |
| EUR | cent | 2 decimals | "5000" = 50.00 EUR |
| CNY | fen | 2 decimals | "10000" = 100.00 CNY |
| JPY | yen | 0 decimals | "1000" = 1000 JPY |
| KRW | won | 0 decimals | "50000" = 50000 KRW |
| GBP | pence | 2 decimals | "2000" = 20.00 GBP |
| SGD | cent | 2 decimals | "1500" = 15.00 SGD |
| HKD | cent | 2 decimals | "7800" = 78.00 HKD |

#### Cryptocurrency Precision

| Currency | Minimum Unit | Precision (Decimals) | Example |
| --- | --- | --- | --- |
| USDT | minimum unit | 6 | "1000000" = 1.000000 USDT |
| USDC | minimum unit | 6 | "1000000" = 1.000000 USDC |
| BTC | satoshi | 8 | "100000000" = 1.00000000 BTC |
| ETH | wei | 18 | "1000000000000000000" = 1.0 ETH |
| TRX | sun | 6 | "1000000" = 1.000000 TRX |
| SOL | lamport | 9 | "1000000000" = 1.000000000 SOL |
| BNB | jager | 8 | "100000000" = 1.00000000 BNB |
| DOGE | koinu | 8 | "100000000" = 1.00000000 DOGE |

#### Notes

1. **Precision Verification**: When request amount precision exceeds currency supported range, returns `INVALID_AMOUNT` error
2. **Exchange Rate Calculation**: When converting fiat to cryptocurrency, system will automatically handle precision conversion
3. **Refund Precision**: Refund amount precision needs to be consistent with original transaction
4. **Minimum Amount**: Each currency has minimum transaction amount limit, specific to merchant configuration

### 7.5 Agreement Type Description

Agreement type (agreementType) defines the deduction mode of agreement payment, affecting deduction frequency, limit configuration, and agreement lifecycle.

#### Agreement Type Comparison

| Type | Description | Applicable Scenarios | Deduction Frequency | Limit Configuration Support | Agreement Lifecycle |
| --- | --- | --- | --- | --- | --- |
| **CYCLE** | Periodic deduction | Fixed periodic deduction for subscription scenarios | Periodic deduction (e.g., monthly) | Single limit + Period limits (DAY/WEEK/MONTH/YEAR) | Long-term validity, expires upon term end or cancellation |
| **NON_CYCLE** | Non-periodic deduction | Non-fixed deduction cycle, merchant can initiate anytime | Irregular deduction (triggered by actual consumption) | Single limit + Period limits (DAY/WEEK/MONTH/YEAR) | Long-term validity, expires upon term end or cancellation |
| **SINGLE** | Single authorization | One-time valid, agreement automatically expires after deduction | One-time deduction only | Single limit only | Short-term validity, automatically expires after successful deduction |

#### Typical Scenario Examples

**CYCLE - Periodic Deduction**
- **Membership Subscription**: Video membership, music subscription, gym monthly card, cloud service annual fee
- **Bill Payment**: Monthly utility bills, property fees, monthly mobile plan fees
- **Characteristics**: Fixed deduction time, amounts may be same or different

**NON_CYCLE - Non-Periodic Deduction**
- **Transportation Services**: Ride-hailing, parking fees, ETC tolls, public transit
- **Food & Beverage**: Food delivery orders, restaurant membership deduction
- **Lifestyle Services**: Laundry, repair, car rental
- **Characteristics**: Triggered by actual consumption, irregular deduction frequency and amounts

**SINGLE - Single Authorization**
- **Pre-authorization Scenarios**: Hotel deposits, car rental deposits
- **One-time Deduction**: One-time authorized payment, temporary deduction
- **Characteristics**: Agreement automatically expires after deduction, no manual cancellation needed

#### Limit Configuration Description

**CYCLE and NON_CYCLE Types**:
- Support **Single Limit** (singleLimit): Maximum amount per deduction
- Support **Period Limits** (periodLimits):
  - DAY: Daily accumulated deduction limit
  - WEEK: Weekly accumulated deduction limit
  - MONTH: Monthly accumulated deduction limit
  - YEAR: Yearly accumulated deduction limit
- Multiple period limits can be configured simultaneously, platform validates all limits

**SINGLE Type**:
- Only supports **Single Limit** (singleLimit)
- Period limits not supported (as agreement expires after deduction)

#### Agreement Lifecycle Comparison

| Operation | CYCLE | NON_CYCLE | SINGLE |
| --- | --- | --- | --- |
| **After Sign** | SIGNED status, can deduct | SIGNED status, can deduct | SIGNED status, can deduct |
| **First Deduction** | Remains SIGNED | Remains SIGNED | Automatically becomes UNSIGNED (agreement expires) |
| **Multiple Deductions** | Supported | Supported | Not supported (expires after first deduction) |
| **User Cancellation** | Supported | Supported | Not applicable (auto-expires after deduction) |
| **Merchant Cancellation** | Supported | Supported | Not applicable (auto-expires after deduction) |
| **Agreement Expiration** | Becomes EXPIRED | Becomes EXPIRED | Not applicable (auto-expires after deduction) |

#### Usage Recommendations

1. **Choose Appropriate Type**:
  - Subscription-based business: Choose **CYCLE**
  - On-demand consumption business: Choose **NON_CYCLE**
  - One-time authorization: Choose **SINGLE**

2. **Limit Configuration Principles**:
  - Single limit should cover most transaction scenarios
  - Period limits prevent excessive short-term deductions
  - CYCLE type recommended to configure monthly limit
  - NON_CYCLE type recommended to configure daily limit

3. **Agreement Management**:
  - CYCLE/NON_CYCLE agreements require active cancellation or await expiration
  - SINGLE agreements auto-expire after deduction, no management needed
  - Recommend setting reasonable validity period (signValidTime) for long-term agreements

### 7.6 Sandbox Environment

#### Environment Information

| Environment | Domain | Description |
| --- | --- | --- |
| Sandbox | api-testnet.bybit.com | Test environment, no real transactions |
| Production | api.bybit.com | Production environment, real transactions |

#### Sandbox Environment Features

1. **Isolated Data**: Sandbox environment data is completely isolated from production environment
2. **Simulated Transactions**: All transactions are simulated, no real fund transfers involved
3. **Feature Consistency**: API definitions, parameters, response formats are consistent with production environment
4. **Relaxed Rate Limits**: Sandbox environment has lower rate limit thresholds, only for functional verification

#### Test Accounts

| Type | Description | How to Obtain |
| --- | --- | --- |
| Merchant Account | Sandbox test merchant | Contact platform operations to enable |
| Test User | Simulated sign user | Auto-created in sandbox environment |
| API Key | Sandbox environment dedicated key | Obtain from merchant dashboard |

#### Testing Recommendations

1. **Complete Flow Testing**: Complete sign→deduction→refund→unsign full flow in sandbox environment
2. **Exception Scenario Simulation**: Use specific amounts to trigger different states (see table below)
3. **Webhook Verification**: Ensure merchant system can correctly receive and process async notifications
4. **Signature Verification**: Verify correctness of signature algorithm implementation

#### Special Amount Trigger Rules

| Amount (Minimum Unit) | Triggered Status | Description |
| --- | --- | --- |
| Ends with 01 | SUCCESS | Immediate success |
| Ends with 02 | PROCESSING | Keeps processing status |
| Ends with 03 | FAILED | Returns insufficient balance |
| Ends with 04 | TIMEOUT | Simulates timeout scenario |
| Ends with 99 | RISK_REJECT | Triggers risk control interception |

**Examples**:
- Amount `100001` → Immediately returns SUCCESS
- Amount `100002` → Keeps PROCESSING, wait for async notification
- Amount `100003` → Returns FAILED, failureReason=BALANCE_NOT_ENOUGH
