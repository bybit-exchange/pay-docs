# Agreement Payment API Documentation

**Document Version**: v2.1

**Update Date**: 2026-01-02

**Update History**:
- v2.1: Internal optimization of deduction API: Support user-defined limit verification (users can set single/daily limits through cashier), downstream payment uses user-configured paymentType (payNow/payLater)
- v2.0: Async notification parameter table supplemented with notify_id/notify_time common fields (4.1-4.6); Deduction API supplemented with fiat currency order request example (3.4); Webhook section added complete Java/Python/Node.js handling code examples (4.7); Signature algorithm section added complete cURL request example (5.4)
- v1.9: binding_info field unified to snake_case naming; refund_amount.total field structure standardized; Added complete status response examples for sign confirmation/unsign/refund APIs; Added sign/refund notification failure examples; Deduction status added TIMEOUT; Added extra_params and scene_info.location field descriptions; Error codes grouped by module; Added chain network list (7.3); Added rate limiting description (2.10); Added sandbox environment description (7.5); Fixed notify_id duplication issue
- v1.8: Unified scene_code enum values; Corrected bindStatus enum; Sign limit configuration supports chain field; Transaction list API supplemented REFUND response; Added API timeout recommendations and concurrency handling description; Added refund status flow diagram; Added API version compatibility description; Added risk_info risk control field; Added failure response and PROCESSING status examples; Added document directory
- v1.7: Added agreement list query API; Transaction query API merged refund query (distinguished by record_type); Transaction list API supports refund record query; Added general specification section (request headers, response format, HTTP status codes, field length limits, idempotency, transaction status flow); GET API examples changed to Query String format; Webhook notification added notify_id deduplication field; Refund notification added user_id field; Sign request added sign_expire_minutes parameter
- v1.6: Moved business flow diagrams and sign lifecycle state machine to Chapter 1 Overview; API paths unified to start with /v5/bybitpay/agreement; Added currency type (fiat/cryptocurrency) support; Added request and response examples for all APIs
- v1.5: Clearly distinguished user_id (platform user ID) and merchant_user_id (merchant-side user ID); All APIs unified required common fields (merchant_id, user_id, agreement_type); Sign API added merchant_user_id for establishing merchant-side to platform-side user mapping
- v1.4: Unified all API required common fields (merchant_id, user_id, agreement_type)
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
  - [3.2 Sign Confirmation API (Optional)](#32-sign-confirmation-api-optional)
  - [3.3 Unsign API](#33-unsign-api)
  - [3.4 Agreement Deduction API (Core)](#34-agreement-deduction-api-core)
  - [3.5 Sign Status Query API](#35-sign-status-query-api)
  - [3.6 Agreement List Query API](#36-agreement-list-query-api)
  - [3.7 Transaction/Refund Query API (Single)](#37-transactionrefund-query-api-single)
  - [3.8 Deduction Transaction List API](#38-deduction-transaction-list-api)
  - [3.9 Deduction Refund API](#39-deduction-refund-api)
- [4. Async Notifications](#4-async-notifications)
  - [4.1 Sign Result Notification](#41-sign-result-notification)
  - [4.2 Deduction Result Notification](#42-deduction-result-notification)
  - [4.3 Agreement Unsign Notification](#43-agreement-unsign-notification)
  - [4.4 Refund Result Notification](#44-refund-result-notification)
  - [4.5 Agreement Suspend Notification](#45-agreement-suspend-notification)
  - [4.6 Agreement Resume Notification](#46-agreement-resume-notification)
  - [4.7 Webhook General Description](#47-webhook-general-description)
- [5. Security Mechanism](#5-security-mechanism)
  - [5.1 Sign Security](#51-sign-security)
  - [5.2 Deduction Security](#52-deduction-security)
  - [5.3 API Security](#53-api-security)
  - [5.4 Signature Algorithm Detailed Description](#54-signature-algorithm-detailed-description)
- [6. Error Codes](#6-error-codes)
- [7. Appendix](#7-appendix)
  - [7.1 Scene Code List](#71-scene-code-list)
  - [7.2 Currency List](#72-currency-list)
  - [7.3 Chain Network List](#73-chain-network-list)
  - [7.4 Amount Precision Description](#74-amount-precision-description)
  - [7.5 Sandbox Environment](#75-sandbox-environment)

---

## 1. API Overview

**Functional Description**: Agreement Payment supports contactless payment scenarios such as ride-hailing and subscriptions

**Applicable Scenarios**: Ride-hailing contactless payment, membership auto-renewal, utility bill payment, parking lot automatic deduction

**Security Mechanism**: Strong authentication for signing + Limit control + Risk control interception + Async notification

**API Version**: v5

**Version Compatibility Description**:
- All current API paths start with `/v5/bybitpay/agreement`
- New fields are added in a backward-compatible manner, existing field semantics will not be deleted or modified
- Merchants should handle new optional fields in responses compatibly (ignore unknown fields)
- Major incompatible changes will be released through new version paths (e.g., /v6), with advance merchant notification

### 1.1 User Identity Association and Sign Flow

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│                            User Identity Association and Sign Flow                │
├──────────────────────────────────────────────────────────────────────────────────┤
│                                                                                  │
│  1. Merchant App → Sign Request(user_id + merchant_user_id) → Platform returns   │
│     sign QR code and URL                                                         │
│                                                                                  │
│  2. User opens platform App to scan → Login/Register platform account →          │
│     Complete identity verification (SMS/Face/Password)                           │
│                                                                                  │
│  3. Platform binds user relationship:                                            │
│     user_id(platform) binding merchant_user_id(merchant-side)                    │
│                                                                                  │
│  4. Sign success → Webhook notifies merchant (agreement_no + user_id +           │
│     merchant_user_id)                                                            │
│                                                                                  │
│                                                                                  │
└──────────────────────────────────────────────────────────────────────────────────┘
```

### 1.2 Sign Sequence Diagram

```
Merchant Server                  Platform                         User App
    │                         │                            │
    │  1.Sign Request         │                            │
    │  (user_id +             │                            │
    │   merchant_user_id)     │                            │
    │ ──────────────────────→ │                            │
    │                         │                            │
    │  2.Return Sign QR Code  │                            │
    │  (qr_code/sign_url)     │                            │
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
    │  (agreement_no +        │                            │
    │   user_id +             │                            │
    │   merchant_user_id)     │                            │
    │                         │                            │
    │ ←────────────────────── │                            │
    │                         │                            │
```

### 1.3 Deduction Flow

```
Merchant Server → Deduction Request(agreement_no) → Platform
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
Merchant Server → Refund Request(trade_no + refund_amount) → Platform
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
| FAILED | Sign Failed | Sign process abnormally terminated (final state) |
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
| PENDING | FAILED | Sign failed/rejected | User rejected sign or sign process abnormal |
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
4. No Webhook notification sent to merchant (timeout is silent processing)

**Notes**:
- Timeout is calculated from sign request creation time (`create_time`)
- Merchant can actively query sign result through sign status query API
- After timeout, merchant can re-initiate sign request

---

## 2. Core API List

| API Name | Request Method | Path |
| --- | --- | --- |
| Sign Request | POST | /v5/bybitpay/agreement/sign |
| Sign Confirmation | POST | /v5/bybitpay/agreement/confirm |
| Unsign | POST | /v5/bybitpay/agreement/unsign |
| Agreement Deduction | POST | /v5/bybitpay/agreement/pay |
| Deduction Refund | POST | /v5/bybitpay/agreement/refund |
| Sign Status Query | GET | /v5/bybitpay/agreement/query |
| Agreement List Query | GET | /v5/bybitpay/agreement/list |
| Transaction/Refund Query | GET | /v5/bybitpay/agreement/pay/query |
| Transaction/Refund List | GET | /v5/bybitpay/agreement/pay/list |

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
  "code": "SUCCESS",
  "message": "ok",
  "data": {
    // Business data
  }
}
```

#### Failure Response

```json
{
  "code": "ERROR_CODE",
  "message": "Error description",
  "data": null
}
```

#### Response Field Description

| Parameter | Type | Description |
| --- | --- | --- |
| code | string | Response code, SUCCESS indicates success, others are error codes |
| message | string | Response message, "ok" on success, error description on failure |
| data | object/null | Response data, null on failure |

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
| Merchant ID | 32 | merchant_id |
| User ID | 64 | user_id, merchant_user_id |
| Agreement No | 64 | agreement_no, external_agreement_no |
| Order No | 64 | out_trade_no, out_refund_no |
| Trade No | 64 | trade_no, refund_no |
| Amount | 32 | amount.total |
| Currency Code | 16 | currency |
| URL | 512 | notify_url, return_url |
| Description | 256 | order_desc, refund_reason |
| Title | 128 | order_title |
| Extra Params | 2048 | extra_params (JSON string) |

### 2.5 Idempotency Description

Idempotency is guaranteed through business unique indexes:

| Business Scenario | Idempotency Key | Unique Index |
| --- | --- | --- |
| Sign Request | external_agreement_no | (merchant_id, external_agreement_no) |
| Deduction Order | out_trade_no | (merchant_id, out_trade_no) |
| Refund Request | out_refund_no | (merchant_id, out_refund_no) |

- **X-Request-Id** is used for request tracing and troubleshooting
- X-Request-Id format requirement: UUID v4, e.g., `550e8400-e29b-41d4-a716-446655440000`
- Repeated requests with the same merchant order number (out_trade_no) return the result of the first request

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
- Each deduction needs to use different `out_trade_no`
- Limit verification is based on real-time used quota, concurrent requests may cause some requests to be rejected due to exceeding quota

**Same Order Repeated Requests**:
- Requests with the same `out_trade_no` are treated as the same transaction
- After the first request succeeds, repeated requests return the first result (idempotent)
- After the first request fails, can use a new `out_trade_no` to re-initiate

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
  "code": "RATE_LIMIT_EXCEEDED",
  "message": "Too many requests, please try again later",
  "data": {
    "retry_after": 1000
  }
}
```

| Field | Description |
| --- | --- |
| retry_after | Recommended retry wait time (milliseconds) |

#### Handling Recommendations

1. **Exponential Backoff**: After triggering rate limit, recommend using exponential backoff strategy for retry (e.g., 1s, 2s, 4s, 8s)
2. **Request Merging**: For batch query scenarios, recommend using list query API instead of multiple single queries
3. **Async Processing**: In high concurrency scenarios, recommend using message queue for peak shaving
4. **Monitoring Alerts**: Recommend monitoring 429 response ratio, adjust request strategy in time

---

## 3. API Details

### 3.1 Sign Request API

**Request Path**: POST /v5/bybitpay/agreement/sign

#### Request Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| merchant_id | string | Yes | Merchant ID |
| user_id | string | Yes | Platform user ID (our platform's user identifier) |
| agreement_type | string | Yes | Sign type: CYCLE(periodic deduction) / SINGLE(single authorization) |
| merchant_user_id | string | Yes | Merchant-side user ID (user identifier in merchant system, used for establishing mapping) |
| scene_code | string | Yes | Scene code (see 7.1 Scene Code List): TAXI/PARKING/SUBSCRIPTION/UTILITY/TOLL/TRANSIT/FOOD/ENTERTAINMENT/EDUCATION/MEMBERSHIP/RENT/FITNESS/TELECOM/CLOUD/INSURANCE/LOAN/OTHERS |
| product_code | string | No | Product code, assigned by platform (optional) |
| external_agreement_no | string | Yes | Merchant agreement number (unique on merchant side) |
| sign_valid_time | string | No | Sign validity period, ISO8601 format |
| single_limit | object | No | Single transaction limit configuration |
| single_limit.amount | string | No | Limit amount (required when passing single_limit) |
| single_limit.currency | string | No | Currency code (required when passing single_limit) |
| single_limit.currency_type | string | No | Currency type: FIAT(fiat) / CRYPTO(cryptocurrency) (required when passing single_limit) |
| single_limit.chain | string | No | Chain network (optional for cryptocurrency, e.g.: ERC20/TRC20/Arbitrum) |
| period_limits | array | No | Period limit configuration list (supports configuring limits for multiple period types) |
| period_limits[].period_type | string | No | Period type: DAY/WEEK/MONTH/YEAR (required when passing period_limits) |
| period_limits[].amount | string | No | Period limit amount (required when passing period_limits) |
| period_limits[].currency | string | No | Currency code (required when passing period_limits) |
| period_limits[].currency_type | string | No | Currency type: FIAT(fiat) / CRYPTO(cryptocurrency) (required when passing period_limits) |
| period_limits[].chain | string | No | Chain network (optional for cryptocurrency, e.g.: ERC20/TRC20/Arbitrum) |
| notify_url | string | Yes | Sign result async notification URL |
| return_url | string | No | Redirect URL after sign completion (can be omitted for App scan scenario) |
| sign_expire_minutes | int | No | Sign link validity period (minutes), default 30, max 1440 (24 hours) |
| extra_params | object | No | Extension parameters (JSON object, used for passing business custom data, platform passes through without processing) |

#### Request Example

```json
{
  "merchant_id": "M123456789",
  "user_id": "U_123456789",
  "agreement_type": "CYCLE",
  "merchant_user_id": "merchant_user_123",
  "scene_code": "SUBSCRIPTION",
  "product_code": "PROD_001",
  "external_agreement_no": "MERCHANT_AGR_001",
  "sign_valid_time": "2026-12-23T10:30:00Z",
  "single_limit": {
    "amount": "100000",
    "currency": "USDT",
    "currency_type": "CRYPTO",
    "chain": "TRC20"
  },
  "period_limits": [
    {
      "period_type": "DAY",
      "amount": "500000",
      "currency": "USDT",
      "currency_type": "CRYPTO",
      "chain": "TRC20"
    }
  ],
  "notify_url": "https://merchant.com/notify/sign",
  "return_url": "https://merchant.com/return",
  "sign_expire_minutes": 60
}
```

#### Response Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| code | string | Response code, SUCCESS/FAIL |
| message | string | Response message |
| data | object | Response data |
| data.sign_order_id | string | Platform sign order number |
| data.sign_url | string | Sign page URL (for H5 redirect) |
| data.qr_code | string | Sign QR code content (for user App scan) |
| data.qr_code_url | string | Sign QR code image URL (can be displayed directly) |
| data.expire_time | string | Sign link/QR code expiration time |

#### Response Example (Success)

```json
{
  "code": "SUCCESS",
  "message": "ok",
  "data": {
    "sign_order_id": "AGR202312230001",
    "sign_url": "https://pay.example.com/sign?token=xxx",
    "qr_code": "https://pay.example.com/sign?token=xxx",
    "qr_code_url": "https://pay.example.com/qr/AGR202312230001.png",
    "expire_time": "2023-12-23T12:30:00Z"
  }
}
```

#### Response Example (Failure)

```json
{
  "code": "PARAM_ERROR",
  "message": "Parameter error: external_agreement_no already exists",
  "data": null
}
```

---

### 3.2 Sign Confirmation API (Optional)

**Request Path**: POST /v5/bybitpay/agreement/confirm

**Description**: After user completes identity verification by scanning QR code in App, platform will automatically complete sign and notify merchant via Webhook. This API is optional, used for merchant to actively query/confirm sign status.

#### Request Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| merchant_id | string | Yes | Merchant ID |
| user_id | string | Yes | Platform user ID (our platform's user identifier) |
| agreement_type | string | Yes | Sign type: CYCLE(periodic deduction) / SINGLE(single authorization) |
| sign_order_id | string | Yes | Platform sign order number |

#### Request Example

```json
{
  "merchant_id": "M123456789",
  "user_id": "U_123456789",
  "agreement_type": "CYCLE",
  "sign_order_id": "AGR202312230001"
}
```

#### Response Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| code | string | Response code |
| message | string | Response message |
| data | object | Response data |
| data.agreement_no | string | Platform agreement number (used for deduction) |
| data.external_agreement_no | string | Merchant agreement number |
| data.user_id | string | Platform user ID |
| data.merchant_user_id | string | Merchant-side user ID |
| data.status | string | Sign status: INIT/PENDING/SIGNED/FAILED |
| data.sign_time | string | Sign success time (returned on success) |
| data.valid_time | string | Agreement validity period |
| data.binding_info | object | User binding information |
| data.binding_info.bind_time | string | Binding time |
| data.binding_info.bind_status | string | Binding status: BOUND (bound) / UNBOUND (unbound) |

#### Response Example (Signed)

```json
{
  "code": "SUCCESS",
  "message": "ok",
  "data": {
    "agreement_no": "AGR202312230001",
    "external_agreement_no": "MERCHANT_AGR_001",
    "user_id": "U_123456789",
    "merchant_user_id": "merchant_user_123",
    "status": "SIGNED",
    "sign_time": "2023-12-23T10:30:00Z",
    "valid_time": "2024-12-23T10:30:00Z",
    "binding_info": {
      "bind_time": "2023-12-23T10:30:00Z",
      "bind_status": "BOUND"
    }
  }
}
```

#### Response Example (Pending Confirmation)

```json
{
  "code": "SUCCESS",
  "message": "ok",
  "data": {
    "agreement_no": "AGR202312230001",
    "external_agreement_no": "MERCHANT_AGR_001",
    "user_id": "U_123456789",
    "merchant_user_id": "merchant_user_123",
    "status": "PENDING",
    "valid_time": "2024-12-23T10:30:00Z",
    "binding_info": {
      "bind_time": "2023-12-23T10:28:00Z",
      "bind_status": "BOUND"
    }
  }
}
```

#### Response Example (Sign Failed)

```json
{
  "code": "SUCCESS",
  "message": "ok",
  "data": {
    "agreement_no": "AGR202312230001",
    "external_agreement_no": "MERCHANT_AGR_001",
    "user_id": "U_123456789",
    "merchant_user_id": "merchant_user_123",
    "status": "FAILED",
    "binding_info": {
      "bind_status": "UNBOUND"
    }
  }
}
```

---

### 3.3 Unsign API

**Request Path**: POST /v5/bybitpay/agreement/unsign

#### Request Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| merchant_id | string | Yes | Merchant ID |
| user_id | string | Yes | Platform user ID (our platform's user identifier) |
| agreement_type | string | Yes | Sign type: CYCLE(periodic deduction) / SINGLE(single authorization) |
| agreement_no | string | Either | Platform agreement number |
| external_agreement_no | string | Either | Merchant agreement number |
| unsign_type | string | No | Unsign type: USER(user active)/MERCHANT(merchant initiated)/SYSTEM(system unsign) |
| unsign_reason | string | No | Unsign reason |

#### Request Example

```json
{
  "merchant_id": "M123456789",
  "user_id": "U_123456789",
  "agreement_type": "CYCLE",
  "agreement_no": "AGR202312230001",
  "unsign_type": "USER",
  "unsign_reason": "User active unsign"
}
```

#### Response Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| code | string | Response code |
| message | string | Response message |
| data | object | Response data |
| data.agreement_no | string | Platform agreement number |
| data.status | string | Status: UNSIGNED |
| data.unsign_time | string | Unsign time |

#### Response Example (Success)

```json
{
  "code": "SUCCESS",
  "message": "ok",
  "data": {
    "agreement_no": "AGR202312230001",
    "status": "UNSIGNED",
    "unsign_time": "2023-12-23T15:30:00Z"
  }
}
```

#### Response Example (Failure - Agreement Not Exist)

```json
{
  "code": "AGREEMENT_NOT_EXIST",
  "message": "Agreement does not exist",
  "data": null
}
```

#### Response Example (Failure - Agreement Already Unsigned)

```json
{
  "code": "AGREEMENT_UNSIGNED",
  "message": "Agreement already unsigned, no need to repeat",
  "data": null
}
```

---

### 3.4 Agreement Deduction API (Core)

**Request Path**: POST /v5/bybitpay/agreement/pay

#### Request Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| merchant_id | string | Yes | Merchant ID |
| user_id | string | Yes | Platform user ID (our platform's user identifier) |
| agreement_type | string | Yes | Sign type: CYCLE(periodic deduction) / SINGLE(single authorization) |
| agreement_no | string | Yes | Platform agreement number |
| out_trade_no | string | Yes | Merchant order number (unique on merchant side) |
| scene_code | string | Yes | Scene code (see 7.1 Scene Code List): TAXI/PARKING/SUBSCRIPTION/UTILITY/TOLL/TRANSIT/FOOD/ENTERTAINMENT/EDUCATION/MEMBERSHIP/RENT/FITNESS/TELECOM/CLOUD/INSURANCE/LOAN/OTHERS |
| amount | object | Yes | Deduction amount |
| amount.total | string | Yes | Deduction amount (minimum unit) |
| amount.currency | string | Yes | Currency code |
| amount.currency_type | string | Yes | Currency type: FIAT(fiat) / CRYPTO(cryptocurrency) |
| amount.chain | string | No | Chain network (required for cryptocurrency, e.g.: ERC20/TRC20/Arbitrum) |
| order_info | object | Yes | Order information |
| order_info.order_title | string | Yes | Order title (displayed to user) |
| order_info.order_desc | string | No | Order description |
| order_info.goods_name | string | No | Goods name |
| order_info.goods_id | string | No | Goods ID |
| order_info.goods_category | string | No | Goods category |
| scene_info | object | No | Scene information |
| scene_info.device_id | string | No | Device ID |
| scene_info.device_ip | string | No | Device IP |
| scene_info.location | object | No | Location information |
| scene_info.location.latitude | string | No | Latitude (e.g.: 39.9042) |
| scene_info.location.longitude | string | No | Longitude (e.g.: 116.4074) |
| scene_info.location.address | string | No | Detailed address |
| notify_url | string | Yes | Deduction result async notification URL |
| risk_info | object | No | Risk control information (optional, for merchant to pass risk-related data) |
| risk_info.user_ip | string | No | User IP address |
| risk_info.device_fingerprint | string | No | Device fingerprint |
| risk_info.user_agent | string | No | User agent string |

#### Response Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| code | string | Response code |
| message | string | Response message |
| data | object | Response data |
| data.order_no | string | Platform order number (internal use) |
| data.trade_no | string | Platform trade number (external display) |
| data.out_trade_no | string | Merchant order number |
| data.status | string | Transaction status: PROCESSING/SUCCESS/FAILED/TIMEOUT |
| data.amount | object | Merchant requested amount (same as request) |
| data.amount.total | string | Amount (minimum unit) |
| data.amount.currency | string | Currency code |
| data.amount.currency_type | string | Currency type: FIAT/CRYPTO |
| data.crypto_payment | object | User's actual cryptocurrency payment info (returned for fiat orders) |
| data.crypto_payment.currency | string | Cryptocurrency currency (e.g.: USDT/BTC/ETH) |
| data.crypto_payment.amount | string | Cryptocurrency amount |
| data.crypto_payment.chain | string | Chain network (e.g.: TRC20/ERC20) |
| data.crypto_payment.exchange_rate | string | Exchange rate (1 fiat = ? cryptocurrency) |
| data.crypto_payment.rate_time | string | Exchange rate lock time |
| data.pay_time | string | Payment success time (returned on success) |
| data.failure_reason | string | Failure reason (returned on failure) |

#### Request Example (Cryptocurrency Order)

```json
{
  "merchant_id": "M123456789",
  "user_id": "U_123456789",
  "agreement_type": "CYCLE",
  "agreement_no": "AGR202312230001",
  "out_trade_no": "TAXI20231223001",
  "scene_code": "TAXI",
  "amount": {
    "total": "2350",
    "currency": "USDT",
    "currency_type": "CRYPTO",
    "chain": "TRC20"
  },
  "order_info": {
    "order_title": "Ride fare",
    "order_desc": "December 23 trip fare",
    "goods_name": "Express service",
    "goods_id": "TAXI_SERVICE_001",
    "goods_category": "Transportation service"
  },
  "scene_info": {
    "device_id": "DEVICE_001",
    "device_ip": "192.168.1.1"
  },
  "risk_info": {
    "user_ip": "203.0.113.45",
    "device_fingerprint": "fp_abc123xyz",
    "user_agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0)"
  },
  "notify_url": "https://merchant.com/notify/pay"
}
```

#### Request Example (Fiat Currency Order)

```json
{
  "merchant_id": "M123456789",
  "user_id": "U_123456789",
  "agreement_type": "CYCLE",
  "agreement_no": "AGR202312230001",
  "out_trade_no": "TAXI20231223002",
  "scene_code": "TAXI",
  "amount": {
    "total": "10000",
    "currency": "USD",
    "currency_type": "FIAT"
  },
  "order_info": {
    "order_title": "Ride fare",
    "order_desc": "December 23 trip fare"
  },
  "notify_url": "https://merchant.com/notify/pay"
}
```

#### Response Example (Cryptocurrency Order)

```json
{
  "code": "SUCCESS",
  "message": "ok",
  "data": {
    "order_no": "ORD202312230001",
    "trade_no": "PAY202312230001",
    "out_trade_no": "TAXI20231223001",
    "status": "SUCCESS",
    "amount": {
      "total": "2350",
      "currency": "USDT",
      "currency_type": "CRYPTO",
      "chain": "TRC20"
    },
    "pay_time": "2023-12-23T10:30:00Z"
  }
}
```

#### Response Example (Fiat Order, User Pays with Cryptocurrency)

```json
{
  "code": "SUCCESS",
  "message": "ok",
  "data": {
    "order_no": "ORD202312230002",
    "trade_no": "PAY202312230002",
    "out_trade_no": "TAXI20231223002",
    "status": "SUCCESS",
    "amount": {
      "total": "10000",
      "currency": "USD",
      "currency_type": "FIAT"
    },
    "crypto_payment": {
      "currency": "USDT",
      "amount": "10005.50",
      "chain": "TRC20",
      "exchange_rate": "1.00055",
      "rate_time": "2023-12-23T10:29:55Z"
    },
    "pay_time": "2023-12-23T10:30:00Z"
  }
}
```

#### Response Example (Processing)

```json
{
  "code": "SUCCESS",
  "message": "ok",
  "data": {
    "order_no": "ORD202312230003",
    "trade_no": "PAY202312230003",
    "out_trade_no": "TAXI20231223003",
    "status": "PROCESSING",
    "amount": {
      "total": "5000",
      "currency": "USDT",
      "currency_type": "CRYPTO",
      "chain": "TRC20"
    }
  }
}
```

#### Response Example (Deduction Failed)

```json
{
  "code": "SUCCESS",
  "message": "ok",
  "data": {
    "order_no": "ORD202312230004",
    "trade_no": "PAY202312230004",
    "out_trade_no": "TAXI20231223004",
    "status": "FAILED",
    "amount": {
      "total": "5000",
      "currency": "USDT",
      "currency_type": "CRYPTO",
      "chain": "TRC20"
    },
    "failure_reason": "BALANCE_NOT_ENOUGH"
  }
}
```

---

### 3.5 Sign Status Query API

**Request Path**: GET /v5/bybitpay/agreement/query

#### Request Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| merchant_id | string | Yes | Merchant ID |
| user_id | string | Yes | Platform user ID (our platform's user identifier) |
| agreement_type | string | Yes | Sign type: CYCLE(periodic deduction) / SINGLE(single authorization) |
| agreement_no | string | Either | Platform agreement number |
| external_agreement_no | string | Either | Merchant agreement number |

#### Request Example

```
GET /v5/bybitpay/agreement/query?merchant_id=M123456789&user_id=U_123456789&agreement_type=CYCLE&agreement_no=AGR202312230001
```

#### Response Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| code | string | Response code |
| data | object | Response data |
| data.agreement_no | string | Platform agreement number |
| data.external_agreement_no | string | Merchant agreement number |
| data.user_id | string | Platform user ID |
| data.merchant_user_id | string | Merchant-side user ID |
| data.status | string | Status: INIT/PENDING/SIGNED/SUSPENDED/UNSIGNED/EXPIRED/FAILED |
| data.sign_time | string | Sign time |
| data.valid_time | string | Validity period |
| data.single_limit | object | Single transaction limit |
| data.period_limits | array | Period limits list (supports multiple period types) |
| data.used_quota | object | Used quota |

#### Response Example

```json
{
  "code": "SUCCESS",
  "message": "ok",
  "data": {
    "agreement_no": "AGR202312230001",
    "external_agreement_no": "MERCHANT_AGR_001",
    "user_id": "U_123456789",
    "merchant_user_id": "merchant_user_123",
    "status": "SIGNED",
    "sign_time": "2023-12-23T10:30:00Z",
    "valid_time": "2024-12-23T10:30:00Z",
    "single_limit": {
      "amount": "100000",
      "currency": "USDT",
      "currency_type": "CRYPTO",
      "chain": "TRC20"
    },
    "period_limits": [
      {
        "period_type": "DAY",
        "amount": "500000",
        "currency": "USDT",
        "currency_type": "CRYPTO",
        "chain": "TRC20"
      }
    ],
    "used_quota": {
      "day_used": "50000",
      "currency": "USDT",
      "currency_type": "CRYPTO"
    }
  }
}
```

---

### 3.6 Agreement List Query API

**Request Path**: GET /v5/bybitpay/agreement/list

**Description**: Query agreement list under merchant, supports pagination and status filtering

#### Request Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| merchant_id | string | Yes | Merchant ID |
| user_id | string | No | Platform user ID (filter agreements for specified user) |
| agreement_type | string | No | Sign type: CYCLE/SINGLE (query all if not passed) |
| status | string | No | Agreement status filter: INIT/PENDING/SIGNED/SUSPENDED/UNSIGNED/EXPIRED/FAILED |
| scene_code | string | No | Scene code filter |
| start_time | string | No | Sign start time (ISO8601 format) |
| end_time | string | No | Sign end time (ISO8601 format) |
| page_no | int | No | Page number, default 1 |
| page_size | int | No | Page size, default 20, max 100 |

#### Request Example

```
GET /v5/bybitpay/agreement/list?merchant_id=M123456789&status=SIGNED&page_no=1&page_size=20
```

#### Response Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| code | string | Response code |
| data | object | Response data |
| data.total | int | Total record count |
| data.page_no | int | Current page number |
| data.page_size | int | Page size |
| data.list | array | Agreement list |
| data.list[].agreement_no | string | Platform agreement number |
| data.list[].external_agreement_no | string | Merchant agreement number |
| data.list[].user_id | string | Platform user ID |
| data.list[].merchant_user_id | string | Merchant-side user ID |
| data.list[].agreement_type | string | Sign type |
| data.list[].scene_code | string | Scene code |
| data.list[].status | string | Agreement status |
| data.list[].sign_time | string | Sign time |
| data.list[].valid_time | string | Validity period |

#### Response Example

```json
{
  "code": "SUCCESS",
  "message": "ok",
  "data": {
    "total": 100,
    "page_no": 1,
    "page_size": 20,
    "list": [
      {
        "agreement_no": "AGR202312230001",
        "external_agreement_no": "MERCHANT_AGR_001",
        "user_id": "U_123456789",
        "merchant_user_id": "merchant_user_123",
        "agreement_type": "CYCLE",
        "scene_code": "SUBSCRIPTION",
        "status": "SIGNED",
        "sign_time": "2023-12-23T10:30:00Z",
        "valid_time": "2024-12-23T10:30:00Z"
      }
    ]
  }
}
```

---

### 3.7 Transaction/Refund Query API (Single)

**Request Path**: GET /v5/bybitpay/agreement/pay/query

**Description**: Query single deduction transaction or refund record details, distinguished by record_type

#### Request Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| merchant_id | string | Yes | Merchant ID |
| user_id | string | Yes | Platform user ID (our platform's user identifier) |
| agreement_type | string | Yes | Sign type: CYCLE(periodic deduction) / SINGLE(single authorization) |
| record_type | string | No | Record type: PAY(deduction transaction)/REFUND(refund record), default PAY |
| trade_no | string | Conditional | Platform trade number (when record_type=PAY, either this or out_trade_no) |
| out_trade_no | string | Conditional | Merchant order number (when record_type=PAY, either this or trade_no) |
| refund_no | string | Conditional | Platform refund number (when record_type=REFUND, either this or out_refund_no) |
| out_refund_no | string | Conditional | Merchant refund number (when record_type=REFUND, either this or refund_no) |

#### Request Example (Query Deduction Transaction)

```
GET /v5/bybitpay/agreement/pay/query?merchant_id=M123456789&user_id=U_123456789&agreement_type=CYCLE&record_type=PAY&trade_no=PAY202312230001
```

#### Request Example (Query Refund Record)

```
GET /v5/bybitpay/agreement/pay/query?merchant_id=M123456789&user_id=U_123456789&agreement_type=CYCLE&record_type=REFUND&refund_no=RF202312230001
```

#### Response Parameters (Deduction Transaction record_type=PAY)

| Parameter | Type | Description |
| --- | --- | --- |
| code | string | Response code |
| data | object | Transaction details |
| data.trade_no | string | Platform trade number |
| data.out_trade_no | string | Merchant order number |
| data.status | string | Transaction status |
| data.amount | object | Merchant requested amount |
| data.crypto_payment | object | User's actual cryptocurrency payment info (returned for fiat orders) |
| data.pay_time | string | Payment time |
| data.refund_amount | object | Refunded amount |

#### Response Parameters (Refund Record record_type=REFUND)

| Parameter | Type | Description |
| --- | --- | --- |
| code | string | Response code |
| data | object | Refund details |
| data.refund_no | string | Platform refund number |
| data.out_refund_no | string | Merchant refund number |
| data.trade_no | string | Original trade number |
| data.status | string | Refund status: PROCESSING/SUCCESS/FAILED |
| data.refund_amount | object | Refund amount |
| data.refund_time | string | Refund success time |
| data.failure_reason | string | Failure reason |

#### Response Example (Deduction Transaction)

```json
{
  "code": "SUCCESS",
  "message": "ok",
  "data": {
    "trade_no": "PAY202312230002",
    "out_trade_no": "TAXI20231223002",
    "status": "SUCCESS",
    "amount": {
      "total": "10000",
      "currency": "USD",
      "currency_type": "FIAT"
    },
    "crypto_payment": {
      "currency": "USDT",
      "amount": "10005.50",
      "chain": "TRC20",
      "exchange_rate": "1.00055",
      "rate_time": "2023-12-23T10:29:55Z"
    },
    "pay_time": "2023-12-23T10:30:00Z",
    "refund_amount": {
      "total": "0",
      "currency": "USD",
      "currency_type": "FIAT"
    }
  }
}
```

#### Response Example (Refund Record)

```json
{
  "code": "SUCCESS",
  "message": "ok",
  "data": {
    "refund_no": "RF202312230001",
    "out_refund_no": "TAXI_RF20231223001",
    "trade_no": "PAY202312230001",
    "status": "SUCCESS",
    "refund_amount": {
      "total": "2350",
      "currency": "USDT",
      "currency_type": "CRYPTO",
      "chain": "TRC20"
    },
    "refund_time": "2023-12-23T11:30:00Z"
  }
}
```

---

### 3.8 Deduction Transaction List API

**Request Path**: GET /v5/bybitpay/agreement/pay/list

**Description**: Query deduction transaction or refund record list under an agreement, supports pagination and time range filtering

#### Request Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| merchant_id | string | Yes | Merchant ID |
| user_id | string | Yes | Platform user ID (our platform's user identifier) |
| agreement_type | string | Yes | Sign type: CYCLE(periodic deduction) / SINGLE(single authorization) |
| agreement_no | string | Yes | Platform agreement number |
| record_type | string | No | Record type: PAY(deduction transaction)/REFUND(refund record), default PAY |
| status | string | No | Status filter: SUCCESS/FAILED/PROCESSING |
| start_time | string | No | Start time (ISO8601 format) |
| end_time | string | No | End time (ISO8601 format) |
| page_no | int | No | Page number, default 1 |
| page_size | int | No | Page size, default 20, max 100 |

#### Request Example

```
GET /v5/bybitpay/agreement/pay/list?merchant_id=M123456789&user_id=U_123456789&agreement_type=CYCLE&agreement_no=AGR202312230001&record_type=PAY&status=SUCCESS&page_no=1&page_size=20
```

#### Response Parameters (Deduction Transaction record_type=PAY)

| Parameter | Type | Description |
| --- | --- | --- |
| code | string | Response code |
| data | object | Response data |
| data.total | int | Total record count |
| data.page_no | int | Current page number |
| data.page_size | int | Page size |
| data.list | array | Transaction list |
| data.list[].trade_no | string | Platform trade number |
| data.list[].out_trade_no | string | Merchant order number |
| data.list[].status | string | Transaction status |
| data.list[].amount | object | Merchant requested amount |
| data.list[].crypto_payment | object | User's actual cryptocurrency payment info (returned for fiat orders) |
| data.list[].pay_time | string | Payment time |
| data.list[].refund_amount | object | Refunded amount |

#### Response Parameters (Refund Record record_type=REFUND)

| Parameter | Type | Description |
| --- | --- | --- |
| code | string | Response code |
| data | object | Response data |
| data.total | int | Total record count |
| data.page_no | int | Current page number |
| data.page_size | int | Page size |
| data.list | array | Refund list |
| data.list[].refund_no | string | Platform refund number |
| data.list[].out_refund_no | string | Merchant refund number |
| data.list[].trade_no | string | Original trade number |
| data.list[].status | string | Refund status: PROCESSING/SUCCESS/FAILED |
| data.list[].refund_amount | object | Refund amount |
| data.list[].refund_time | string | Refund success time |
| data.list[].failure_reason | string | Failure reason (returned on failure) |

#### Response Example (Deduction Transaction record_type=PAY)

```json
{
  "code": "SUCCESS",
  "message": "ok",
  "data": {
    "total": 50,
    "page_no": 1,
    "page_size": 20,
    "list": [
      {
        "trade_no": "PAY202312230001",
        "out_trade_no": "TAXI20231223001",
        "status": "SUCCESS",
        "amount": {
          "total": "10000",
          "currency": "USD",
          "currency_type": "FIAT"
        },
        "crypto_payment": {
          "currency": "USDT",
          "amount": "10005.50",
          "chain": "TRC20",
          "exchange_rate": "1.00055",
          "rate_time": "2023-12-23T10:29:55Z"
        },
        "pay_time": "2023-12-23T10:30:00Z",
        "refund_amount": {
          "total": "0",
          "currency": "USD",
          "currency_type": "FIAT"
        }
      }
    ]
  }
}
```

#### Response Example (Refund Record record_type=REFUND)

```json
{
  "code": "SUCCESS",
  "message": "ok",
  "data": {
    "total": 10,
    "page_no": 1,
    "page_size": 20,
    "list": [
      {
        "refund_no": "RF202312230001",
        "out_refund_no": "TAXI_RF20231223001",
        "trade_no": "PAY202312230001",
        "status": "SUCCESS",
        "refund_amount": {
          "total": "2350",
          "currency": "USDT",
          "currency_type": "CRYPTO",
          "chain": "TRC20"
        },
        "refund_time": "2023-12-23T11:30:00Z"
      }
    ]
  }
}
```

---

### 3.9 Deduction Refund API

**Request Path**: POST /v5/bybitpay/agreement/refund

**Description**: Initiate refund for successful deduction transaction, supports full and partial refund

#### Request Parameters

| Parameter | Type | Required | Description |
| --- | --- | --- | --- |
| merchant_id | string | Yes | Merchant ID |
| user_id | string | Yes | Platform user ID (our platform's user identifier) |
| agreement_type | string | Yes | Sign type: CYCLE(periodic deduction) / SINGLE(single authorization) |
| trade_no | string | Either | Platform trade number |
| out_trade_no | string | Either | Merchant order number |
| out_refund_no | string | Yes | Merchant refund number (unique on merchant side) |
| refund_amount | object | Yes | Refund amount |
| refund_amount.total | string | Yes | Refund amount (minimum unit) |
| refund_amount.currency | string | Yes | Currency code |
| refund_amount.currency_type | string | Yes | Currency type: FIAT(fiat) / CRYPTO(cryptocurrency) |
| refund_amount.chain | string | No | Chain network (required for cryptocurrency) |
| refund_reason | string | No | Refund reason |
| notify_url | string | Yes | Refund result async notification URL |

#### Request Example

```json
{
  "merchant_id": "M123456789",
  "user_id": "U_123456789",
  "agreement_type": "CYCLE",
  "trade_no": "PAY202312230001",
  "out_refund_no": "TAXI_RF20231223001",
  "refund_amount": {
    "total": "2350",
    "currency": "USDT",
    "currency_type": "CRYPTO",
    "chain": "TRC20"
  },
  "refund_reason": "User cancelled order",
  "notify_url": "https://merchant.com/notify/refund"
}
```

#### Response Parameters

| Parameter | Type | Description |
| --- | --- | --- |
| code | string | Response code |
| message | string | Response message |
| data | object | Response data |
| data.refund_no | string | Platform refund number |
| data.out_refund_no | string | Merchant refund number |
| data.trade_no | string | Original trade number |
| data.status | string | Refund status: PROCESSING/SUCCESS/FAILED |
| data.refund_amount | object | Refund amount |
| data.refund_time | string | Refund success time (returned on success) |
| data.failure_reason | string | Failure reason (returned on failure) |

#### Response Example (Success)

```json
{
  "code": "SUCCESS",
  "message": "ok",
  "data": {
    "refund_no": "RF202312230001",
    "out_refund_no": "TAXI_RF20231223001",
    "trade_no": "PAY202312230001",
    "status": "SUCCESS",
    "refund_amount": {
      "total": "2350",
      "currency": "USDT",
      "currency_type": "CRYPTO",
      "chain": "TRC20"
    },
    "refund_time": "2023-12-23T11:30:00Z"
  }
}
```

#### Response Example (Processing)

```json
{
  "code": "SUCCESS",
  "message": "ok",
  "data": {
    "refund_no": "RF202312230002",
    "out_refund_no": "TAXI_RF20231223002",
    "trade_no": "PAY202312230001",
    "status": "PROCESSING",
    "refund_amount": {
      "total": "2350",
      "currency": "USDT",
      "currency_type": "CRYPTO",
      "chain": "TRC20"
    }
  }
}
```

#### Response Example (Failed)

```json
{
  "code": "SUCCESS",
  "message": "ok",
  "data": {
    "refund_no": "RF202312230003",
    "out_refund_no": "TAXI_RF20231223003",
    "trade_no": "PAY202312230001",
    "status": "FAILED",
    "refund_amount": {
      "total": "2350",
      "currency": "USDT",
      "currency_type": "CRYPTO",
      "chain": "TRC20"
    },
    "failure_reason": "REFUND_AMOUNT_EXCEED"
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
  "notifyType": "AGREEMENT_SIGN",         // Notification type
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
| notifyTime | string | Notification send time (format: yyyy-MM-dd HH:mm:ss) |
| merchantId | string | Merchant ID |
| data | object | Business data (different structure based on notifyType) |
| sign | string | Signature value (Base64 encoded) |
| signType | string | Signature algorithm, fixed as RSA2 |

### Notification Type Enum

| notifyType | Description |
| --- | --- |
| AGREEMENT_SIGN | Sign result notification |
| AGREEMENT_PAY | Deduction result notification |
| AGREEMENT_REFUND | Refund result notification |
| AGREEMENT_UNSIGN | Agreement unsign notification |
| AGREEMENT_SUSPEND | Agreement suspend notification |
| AGREEMENT_RESUME | Agreement resume notification |

---

### 4.1 Sign Result Notification

**Description**: After user scans QR code, completes identity verification and signs successfully, platform pushes sign result notification to merchant

#### data Field Description

| Parameter | Type | Description |
| --- | --- | --- |
| agreementNo | string | Platform agreement number |
| externalAgreementNo | string | Merchant agreement number |
| agreementType | string | Sign type: CYCLE/SINGLE |
| status | string | Sign status: SIGNED/FAILED |
| userId | string | Platform user ID |
| merchantUserId | string | Merchant-side user ID |
| sceneCode | string | Scene code |
| signTime | string | Sign time |
| failureReason | string | Failure reason (returned on failure) |

#### Notification Example (Success)

```json
{
  "notifyId": "NOTIFY202312230001",
  "notifyType": "AGREEMENT_SIGN",
  "notifyTime": "2023-12-23 10:30:05",
  "merchantId": "M123456789",
  "data": {
    "agreementNo": "AGR202312230001",
    "externalAgreementNo": "MERCHANT_AGR_001",
    "agreementType": "CYCLE",
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
  "notifyType": "AGREEMENT_SIGN",
  "notifyTime": "2023-12-23 10:35:05",
  "merchantId": "M123456789",
  "data": {
    "agreementNo": "AGR202312230002",
    "externalAgreementNo": "MERCHANT_AGR_002",
    "agreementType": "CYCLE",
    "status": "FAILED",
    "userId": "U_123456789",
    "merchantUserId": "merchant_user_123",
    "sceneCode": "TAXI",
    "failureReason": "USER_AUTH_TIMEOUT"
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
| amount.currency_type | string | Currency type: FIAT/CRYPTO |
| payTime | string | Payment time |
| failureReason | string | Failure reason (returned on failure) |

#### Notification Example (Success)

```json
{
  "notifyId": "NOTIFY202312230002",
  "notifyType": "AGREEMENT_PAY",
  "notifyTime": "2023-12-23 10:30:05",
  "merchantId": "M123456789",
  "data": {
    "orderNo": "ORD202312230001",
    "tradeNo": "PAY202312230001",
    "outTradeNo": "TAXI20231223001",
    "agreementNo": "AGR202312230001",
    "status": "SUCCESS",
    "amount": {
      "total": "2350",
      "currency": "USDT",
      "currency_type": "CRYPTO"
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
  "notifyType": "AGREEMENT_PAY",
  "notifyTime": "2023-12-23 10:30:05",
  "merchantId": "M123456789",
  "data": {
    "orderNo": "ORD202312230003",
    "tradeNo": "PAY202312230003",
    "outTradeNo": "TAXI20231223003",
    "agreementNo": "AGR202312230001",
    "status": "FAILED",
    "amount": {
      "total": "5000",
      "currency": "USDT",
      "currency_type": "CRYPTO"
    },
    "failureReason": "BALANCE_NOT_ENOUGH"
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
  "notifyType": "AGREEMENT_UNSIGN",
  "notifyTime": "2023-12-23 15:30:05",
  "merchantId": "M123456789",
  "data": {
    "agreementNo": "AGR202312230001",
    "externalAgreementNo": "MERCHANT_AGR_001",
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
| refund_amount | object | Refund amount object |
| refund_amount.total | string | Refund amount (minimum unit) |
| refund_amount.currency | string | Currency code |
| refund_amount.currency_type | string | Currency type: FIAT/CRYPTO |
| refundTime | string | Refund success time |
| failureReason | string | Failure reason (returned on failure) |

#### Notification Example (Success)

```json
{
  "notifyId": "NOTIFY202312230005",
  "notifyType": "AGREEMENT_REFUND",
  "notifyTime": "2023-12-23 11:30:05",
  "merchantId": "M123456789",
  "data": {
    "orderNo": "ORD202312230005",
    "refundNo": "RF202312230001",
    "outRefundNo": "TAXI_RF20231223001",
    "tradeNo": "PAY202312230001",
    "outTradeNo": "TAXI20231223001",
    "agreementNo": "AGR202312230001",
    "status": "SUCCESS",
    "refund_amount": {
      "total": "2350",
      "currency": "USDT",
      "currency_type": "CRYPTO"
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
  "notifyType": "AGREEMENT_REFUND",
  "notifyTime": "2023-12-23 11:30:05",
  "merchantId": "M123456789",
  "data": {
    "orderNo": "ORD202312230006",
    "refundNo": "RF202312230002",
    "outRefundNo": "TAXI_RF20231223002",
    "tradeNo": "PAY202312230001",
    "outTradeNo": "TAXI20231223001",
    "agreementNo": "AGR202312230001",
    "status": "FAILED",
    "refund_amount": {
      "total": "2350",
      "currency": "USDT",
      "currency_type": "CRYPTO"
    },
    "failureReason": "BALANCE_NOT_ENOUGH"
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
  "notifyType": "AGREEMENT_SUSPEND",
  "notifyTime": "2023-12-23 16:30:05",
  "merchantId": "M123456789",
  "data": {
    "agreementNo": "AGR202312230001",
    "externalAgreementNo": "MERCHANT_AGR_001",
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
  "notifyType": "AGREEMENT_RESUME",
  "notifyTime": "2023-12-23 18:30:05",
  "merchantId": "M123456789",
  "data": {
    "agreementNo": "AGR202312230001",
    "externalAgreementNo": "MERCHANT_AGR_001",
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
| agreementType | string | Sign type: CYCLE/SINGLE |
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
| amount.currency_type | string | Currency type: FIAT/CRYPTO |
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
      "currency_type": "CRYPTO"
    },
    "failureReason": "ORDER_TIMEOUT",
    "timeoutTime": "2023-12-23 12:00:00"
  },
  "sign": "Base64 encoded signature",
  "signType": "RSA2"
}
```

---

### 4.9 Webhook General Description

#### Request Headers

| Parameter | Type | Description |
| --- | --- | --- |
| X-Timestamp | string | Notification timestamp (milliseconds) |
| X-Signature | string | Notification signature (for verification) |
| X-Nonce | string | Random string |
| Content-Type | string | application/json |

#### Notification Common Fields

All Webhook notifications include the following common fields:

| Parameter | Type | Description |
| --- | --- | --- |
| notify_id | string | Notification unique identifier (for merchant deduplication) |
| notify_type | string | Notification type |
| notify_time | string | Notification send time (ISO8601 format) |

**Deduplication Note**: Merchant should deduplicate based on `notify_id`, same notify_id notification only needs to be processed once

#### Retry Mechanism

| Configuration | Description |
| --- | --- |
| Retry count | Maximum 5 retries |
| Retry interval | 15s, 30s, 1min, 5min, 30min |
| Success indicator | Merchant returns HTTP 200 with body as plain text `success` (case insensitive) |
| Timeout | Single request timeout 10 seconds (connect/read/write each 10 seconds) |

#### Webhook Request Body Structure

Platform pushes Webhook request body in JSON format, containing the following fields:

| Parameter | Type | Description |
| --- | --- | --- |
| notifyId | string | Notification unique identifier (for merchant deduplication) |
| notifyType | string | Notification type (see enum below) |
| notifyTime | string | Notification send time (ISO8601 format) |
| merchantId | string | Merchant ID |
| data | object | Business data (different structure based on notifyType) |
| sign | string | Signature value (Base64 encoded) |
| signType | string | Signature algorithm, fixed as `RSA2` |

#### Notification Type Enum

| notifyType | Description |
| --- | --- |
| AGREEMENT_SIGN | Sign result notification |
| AGREEMENT_PAY | Deduction result notification |
| AGREEMENT_REFUND | Refund result notification |
| AGREEMENT_UNSIGN | Agreement unsign notification |
| AGREEMENT_SUSPEND | Agreement suspend notification |
| AGREEMENT_RESUME | Agreement resume notification |
| AGREEMENT_TIMEOUT | Sign timeout notification |
| ORDER_TIMEOUT | Order timeout notification |

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
            @RequestBody String body) {

        // 1. Verify signature (verify from sign field in request body)
        JSONObject notify = JSON.parseObject(body);
        String sign = notify.getString("sign");
        String signType = notify.getString("signType");

        // Content for verification after removing sign and signType
        notify.remove("sign");
        notify.remove("signType");
        String contentToVerify = notify.toJSONString();

        if (!verifySignature(contentToVerify, sign)) {
            log.warn("Webhook signature verification failed");
            return ResponseEntity.status(400).body("signature_error");
        }

        // 2. Verify timestamp (prevent replay attack)
        long ts = Long.parseLong(timestamp);
        if (Math.abs(System.currentTimeMillis() - ts) > 5 * 60 * 1000) {
            log.warn("Webhook timestamp expired");
            return ResponseEntity.status(400).body("timestamp_expired");
        }

        // 3. Parse notification content
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
                case "AGREEMENT_SIGN":
                    notifyService.handleSignNotify(data);
                    break;
                case "AGREEMENT_PAY":
                    notifyService.handlePayNotify(data);
                    break;
                case "AGREEMENT_REFUND":
                    notifyService.handleRefundNotify(data);
                    break;
                case "AGREEMENT_UNSIGN":
                    notifyService.handleUnsignNotify(data);
                    break;
                case "AGREEMENT_SUSPEND":
                    notifyService.handleSuspendNotify(data);
                    break;
                case "AGREEMENT_RESUME":
                    notifyService.handleResumeNotify(data);
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
    body = request.get_data(as_text=True)

    # 2. Parse notification content
    notify = json.loads(body)
    sign = notify.pop('sign', None)
    sign_type = notify.pop('signType', None)

    # 3. Verify signature (content after removing sign and signType)
    content_to_verify = json.dumps(notify, separators=(',', ':'), ensure_ascii=False)
    if not verify_signature(content_to_verify, sign):
        return make_response("signature_error", 400)

    # 4. Verify timestamp (prevent replay attack)
    if abs(int(time.time() * 1000) - int(timestamp)) > 5 * 60 * 1000:
        return make_response("timestamp_expired", 400)

    # 5. Get notification info
    notify_id = notify.get('notifyId')
    notify_type = notify.get('notifyType')
    data = notify.get('data', {})

    # 6. Idempotency check
    if notify_id in processed_notifies:
        return make_response("success", 200)

    # 7. Process business
    try:
        if notify_type == 'AGREEMENT_SIGN':
            handle_sign_notify(data)
        elif notify_type == 'AGREEMENT_PAY':
            handle_pay_notify(data)
        elif notify_type == 'AGREEMENT_REFUND':
            handle_refund_notify(data)
        elif notify_type == 'AGREEMENT_UNSIGN':
            handle_unsign_notify(data)
        elif notify_type == 'AGREEMENT_SUSPEND':
            handle_suspend_notify(data)
        elif notify_type == 'AGREEMENT_RESUME':
            handle_resume_notify(data)

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
  const body = req.rawBody.toString();

  // 1. Parse notification content
  const notify = JSON.parse(body);
  const { sign, signType, ...contentObj } = notify;

  // 2. Verify signature (content after removing sign and signType)
  const contentToVerify = JSON.stringify(contentObj);
  if (!verifySignature(contentToVerify, sign)) {
    return res.status(400).send('signature_error');
  }

  // 3. Verify timestamp (prevent replay attack)
  if (Math.abs(Date.now() - parseInt(timestamp)) > 5 * 60 * 1000) {
    return res.status(400).send('timestamp_expired');
  }

  // 4. Get notification info
  const { notifyId, notifyType, data } = contentObj;

  // 5. Idempotency check
  if (processedNotifies.has(notifyId)) {
    return res.status(200).send('success');
  }

  // 6. Process business
  try {
    switch (notifyType) {
      case 'AGREEMENT_SIGN':
        await handleSignNotify(data);
        break;
      case 'AGREEMENT_PAY':
        await handlePayNotify(data);
        break;
      case 'AGREEMENT_REFUND':
        await handleRefundNotify(data);
        break;
      case 'AGREEMENT_UNSIGN':
        await handleUnsignNotify(data);
        break;
      case 'AGREEMENT_SUSPEND':
        await handleSuspendNotify(data);
        break;
      case 'AGREEMENT_RESUME':
        await handleResumeNotify(data);
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

**Note**: Quota verification (single limit, period limit, balance check) is handled by downstream transaction service (bybitpay-transaction-service).

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
/v5/bybitpay/agreement/pay
1703318400000
{"merchant_id":"M123456789","user_id":"U_123456789",...}
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
API_PATH="/v5/bybitpay/agreement/pay"
MERCHANT_PRIVATE_KEY="./merchant_private_key.pem"
ACCESS_TOKEN="your_access_token"

# Request body
REQUEST_BODY='{
  "merchant_id": "M123456789",
  "user_id": "U_123456789",
  "agreement_type": "CYCLE",
  "agreement_no": "AGR202312230001",
  "out_trade_no": "TAXI20231224001",
  "scene_code": "TAXI",
  "amount": {
    "total": "2350",
    "currency": "USDT",
    "currency_type": "CRYPTO",
    "chain": "TRC20"
  },
  "order_info": {
    "order_title": "Ride fare"
  },
  "notify_url": "https://merchant.com/notify/pay"
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
  "code": "SUCCESS",
  "message": "ok",
  "data": {
    "trade_no": "PAY202312240001",
    "out_trade_no": "TAXI20231224001",
    "status": "PROCESSING",
    "amount": {
      "total": "2350",
      "currency": "USDT",
      "currency_type": "CRYPTO",
      "chain": "TRC20"
    }
  }
}
```

#### Webhook Signature Verification

Merchant needs to verify signature after receiving Webhook notification to prevent forged requests.

**Verification Steps**:

1. Get `sign` and `signType` fields from request body
2. Remove `sign` and `signType` fields from request body to get content to verify
3. Use platform public key to verify signature (RSA2/SHA256withRSA)
4. Get `X-Timestamp` from request header, verify timestamp is within 5 minutes

**Code Example (Java)**:

```java
import java.security.*;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;
import com.alibaba.fastjson.JSONObject;

public class WebhookVerifier {

    /**
     * Verify Webhook signature
     * @param body Original request body JSON string
     * @param timestamp X-Timestamp from request header
     * @param platformPublicKey Platform public key (PEM format or Base64 encoded)
     */
    public boolean verifyWebhook(String body, String timestamp,
                                  String platformPublicKey) throws Exception {
        // 1. Check timestamp (prevent replay attack)
        long now = System.currentTimeMillis();
        long ts = Long.parseLong(timestamp);
        if (Math.abs(now - ts) > 5 * 60 * 1000) {
            return false; // Timestamp expired
        }

        // 2. Parse request body, extract signature
        JSONObject notify = JSONObject.parseObject(body);
        String sign = notify.getString("sign");
        String signType = notify.getString("signType");

        // 3. Remove sign and signType, construct content to verify
        notify.remove("sign");
        notify.remove("signType");
        String contentToVerify = notify.toJSONString();

        // 4. Use RSA2 to verify signature (SHA256withRSA)
        return verifyRSA2(contentToVerify, sign, platformPublicKey);
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
| 139001013 | AGREEMENT_TYPE_MISMATCH | Agreement type mismatch | Agreement type mismatch | Check if agreement type (CYCLE/SINGLE) is correct |

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

### 6.8 System Error Codes

| Error Code | Error Identifier | English Description (retMsg) | Chinese Description | Handling Suggestion |
| --- | --- | --- | --- | --- |
| 50000 | SYSTEM_ERROR | System error | System error | Please retry later or contact technical support |
| 50001 | SERVICE_UNAVAILABLE | Service unavailable | Service unavailable | System under maintenance, please retry later |
| 50002 | DOWNSTREAM_ERROR | Downstream service error | Downstream service error | Please retry later or contact technical support |

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

### 7.5 Sandbox Environment

#### Environment Information

| Environment | Domain | Description |
| --- | --- | --- |
| Sandbox | api.testnet.bybit.com | Test environment, no real transactions |
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
- Amount `100003` → Returns FAILED, failure_reason=BALANCE_NOT_ENOUGH
