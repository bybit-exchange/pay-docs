---
title: AI Integration Skill
sidebar_label: Skills
sidebar_position: 0
---

# Bybit Pay — AI Integration Skill

> Single-file reference for AI-assisted merchant integration of Bybit Pay QR Payment and Recurring Payments (Auto-Deduction) APIs.

---

## Products Overview

| Product | Use Case | Key Flow |
|:--------|:---------|:---------|
| **QR Payment** | One-time scan-to-pay | Create order → Display QR → Webhook notify |
| **Recurring Payments** | Auto-deduction (utilities, subscriptions, ride-hailing) | Sign agreement → Deduct → Webhook notify |

Base URL:
- Mainnet: `https://api2.bybit.com` or `https://api.bytick.com`
- Testnet: `https://api2-testnet.bybit.com`

---

## Authentication (Both Products)

Both QR Payment and Recurring Payments use identical Bybit standard API authentication.

### Required Headers

```http
X-BAPI-API-KEY:     {your_api_key}
X-BAPI-TIMESTAMP:   {unix_ms}          # milliseconds, e.g. 1736233200000
X-BAPI-SIGN:        {signature}
X-BAPI-RECV-WINDOW: 5000               # default 5000ms, max 10000ms
Content-Type:       application/json
```

> **QR Payment only:** also add `Version: 5.00` header.

### Signature Construction

**Step 1 — Build the plain string:**

```
# POST request
plain = timestamp + api_key + recv_window + raw_json_body

# GET request
plain = timestamp + api_key + recv_window + raw_query_string
# raw_query_string must be unescaped: name=foo&age=18 ✓  name%3Dfoo ✗
```

**Step 2 — Sign:**

```
# HMAC_SHA256 (system-generated API key) → hex string
X-BAPI-SIGN = HEX( HMAC_SHA256(plain, api_secret) )

# RSA_SHA256 (self-generated API key) → base64 string
X-BAPI-SIGN = Base64( RSA_SHA256_Sign(plain, merchant_private_key) )
```

**Example (POST):**
```
plain = "1736233200000<api_key>5000{"merchant_id":"M123456789",...}"
```

**Timestamp constraint:** `server_time - recv_window ≤ timestamp < server_time + 1000`

> Reference implementations: https://github.com/bybit-exchange/api-usage-examples

### Common Response Envelope

```json
{
  "retCode": 100000,
  "retMsg": "success",
  "result": { },
  "retExtInfo": {},
  "time": 1736233200000
}
```

`retCode=100000` (QR Payment) or `retCode=20000` (Recurring Payments) indicates success.

---

## When to Use — Business Scenarios & API Flow

### Scenario 1: E-Commerce Checkout (QR Payment)

**When:** User checks out on web/app, pays once by scanning a QR code.

```
1. POST /v5/bybitpay/create_pay       → get qrContent (base64 image) + checkoutLink
2. Display QR to user
3. POST {webhookUrl}                   ← Bybit notifies payment result (PAY_SUCCESS / PAY_FAILED)
4. GET  /v5/bybitpay/pay_result        → poll if webhook not received (fallback)
5. POST /v5/bybitpay/refund            → if refund needed (supports partial & batch)
```

**Minimal request body:**
```json
{
  "merchantId": "305142568",
  "paymentType": "E_COMMERCE",
  "merchantTradeNo": "ORDER-20260107-001",
  "orderAmount": "23.50",
  "currency": "USDT",
  "currencyType": "crypto",
  "orderExpireTime": 1736236800,
  "webhookUrl": "https://merchant.com/webhook/pay",
  "env": { "terminalType": "WEB", "device": "Chrome/133", "browserVersion": "133.0", "ip": "203.0.113.50" }
}
```

> **Amount format (QR Payment):** decimal string, e.g. `"23.50"` = 23.50 USDT

---

### Scenario 2: Subscription / Membership Auto-Renewal (Recurring — CYCLE)

**When:** Monthly/yearly fixed-cycle deduction (video membership, cloud service, gym card).

```
1. POST /v5/bybitpay/agreement/sign   → get qr_code / sign_url for user to authorize
2. Display QR to user (user verifies with SMS/Face/Password)
3. POST {notify_url}                  ← Bybit notifies SIGNED status (agreement_no returned)
4. [Each billing cycle]
   POST /v5/bybitpay/agreement/pay   → deduct using agreement_no
5. POST {notify_url}                  ← Bybit notifies deduction result
6. GET  /v5/bybitpay/agreement/pay/query → query if webhook not received
7. POST /v5/bybitpay/agreement/refund  → refund if needed
8. POST /v5/bybitpay/agreement/unsign  → terminate when user cancels
```

**Minimal deduction request body:**
```json
{
  "merchant_id": "M123456789",
  "user_id": "U_123456789",
  "agreement_type": "CYCLE",
  "agreement_no": "AGR202601070001",
  "out_trade_no": "ORDER-20260107-001",
  "scene_code": "SUBSCRIPTION",
  "amount": { "total": "2350", "currency": "USDT", "currency_type": "CRYPTO", "chain": "TRC20" },
  "order_info": { "order_title": "Monthly subscription - Jan 2026" },
  "notify_url": "https://merchant.com/webhook/deduction"
}
```

> **Amount format (Recurring Payments):** minimum unit integer string, e.g. `"2350"` = 23.50 USDT (2 decimals)。
> Verify agreement `status == SIGNED` via `GET /v5/bybitpay/agreement/query` before deducting.

---

### Scenario 3: On-Demand Consumption (Recurring — NON_CYCLE)

**When:** Irregular deductions triggered by actual usage (ride-hailing, parking, food delivery).

```
1. POST /v5/bybitpay/agreement/sign   → user authorizes once (agreement_type: NON_CYCLE)
3. [Each consumption event]
   POST /v5/bybitpay/agreement/pay   → deduct; include scene_info.device_ip & location
4. POST {notify_url}                  ← async result notification
```

**Difference from CYCLE:** No fixed schedule; merchant initiates deduction whenever a transaction occurs.

---

### Scenario 4: One-Time Pre-Authorization (Recurring — SINGLE)

**When:** Hotel deposit, car rental deposit — one authorization, one deduction, auto-expires.

```
1. POST /v5/bybitpay/agreement/sign   (agreement_type: SINGLE)
2. User signs
3. POST /v5/bybitpay/agreement/pay    → one deduction only
   Agreement automatically becomes UNSIGNED after deduction
```

---

### Scenario 5: Merchant Payout to User

**When:** Merchant sends crypto to a Bybit user (rewards, cashback, refund to wallet).

```
1. POST /v5/bybitpay/payout           → paymentType: MERCHANT_PAYOUT
2. GET  /v5/bybitpay/pay_result       → query status (or receive webhook)
```

**Note:** Requires `payee.uid` (Bybit user UID) and `mccCode`.

---

### Scenario 6: FX Conversion Before Payment

**When:** Merchant wants to quote exchange rate before creating an order in a different settlement currency.

```
1. POST /v5/bybitpay/fx/convert       → get quotationId + exchange rate
2. POST /v5/bybitpay/create_pay       → include quotationId to lock the rate
```

---

## API Reference Summary

### QR Payment APIs

| Method | Endpoint | Purpose |
|:-------|:---------|:--------|
| POST | `/v5/bybitpay/create_pay` | Create order, get QR code |
| GET | `/v5/bybitpay/pay_result` | Query payment/refund status |
| POST | `/v5/bybitpay/refund` | Refund (single, partial, or batch) |
| POST | `/v5/bybitpay/payout` | Payout to Bybit user |
| POST | `/v5/bybitpay/fx/convert` | Get FX quote |
| POST | `{webhookUrl}` (inbound) | Receive payment/refund result |
| POST | `/v5/bybitpay/paystatus/mock` | Mock status in sandbox only |

### Recurring Payments APIs

| Method | Endpoint | Purpose |
|:-------|:---------|:--------|
| POST | `/v5/bybitpay/agreement/sign` | Create sign request (get QR for user) |
| POST | `/v5/bybitpay/agreement/unsign` | Terminate agreement |
| POST | `/v5/bybitpay/agreement/pay` | Execute deduction |
| POST | `/v5/bybitpay/agreement/pay-with-sign` | Sign + deduct in one step (NON_CYCLE / SINGLE) |
| POST | `/v5/bybitpay/agreement/refund` | Refund deduction |
| GET | `/v5/bybitpay/agreement/query` | Query single agreement (check SIGNED status) |
| GET | `/v5/bybitpay/agreement/list` | List agreements (paginated) |
| GET | `/v5/bybitpay/agreement/pay/query` | Query single transaction/refund |
| GET | `/v5/bybitpay/agreement/pay/list` | List transactions (paginated) |

---

## Best Practices

### 1. Signature Verification (Webhook Authentication)

Bybit signs every webhook it sends to you. **Always verify before processing.**

#### QR Payment Webhook Verification

Headers from Bybit: `timestamp` (Unix seconds, 10 digits), `signature`

```python
# Verify incoming QR Payment webhook
def verify_qr_webhook(timestamp: str, signature: str, raw_body: str, bybit_public_key) -> bool:
    content = timestamp + raw_body          # timestamp is seconds (10 digits)
    sig_bytes = base64.b64decode(signature)
    # Verify: SHA256 + RSA PKCS1v15 (1024-bit key)
    try:
        bybit_public_key.verify(sig_bytes, content.encode(), padding.PKCS1v15(), hashes.SHA256())
        return True
    except Exception:
        return False
```

**Critical:** Use the raw request body string — do NOT re-serialize the parsed JSON.

#### Recurring Payments Webhook Verification

Headers from Bybit: `X-Timestamp` (ms), `X-Signature`, `X-Nonce`, `X-Sign-Type: RSA2`

```java
// Verify incoming Recurring Payments webhook
public boolean verifyRecurringWebhook(String timestamp, String nonce,
                                       String signature, String rawBody,
                                       PublicKey platformPublicKey) throws Exception {
    // Timestamp must be within 5 minutes
    if (Math.abs(System.currentTimeMillis() - Long.parseLong(timestamp)) > 5 * 60 * 1000) {
        return false;
    }
    // Sign content = timestamp + nonce + rawBody
    String content = timestamp + nonce + rawBody;
    Signature sig = Signature.getInstance("SHA256withRSA");
    sig.initVerify(platformPublicKey);
    sig.update(content.getBytes("UTF-8"));
    return sig.verify(Base64.getDecoder().decode(signature));
}
```

**Webhook response:** Always return HTTP 200 with plain text body `success`. Bybit retries up to 5 times (15s → 30s → 1min → 5min → 30min).

> **Platform public key:** Download from Bybit Merchant Portal → API Management → Platform Public Key. Required for webhook signature verification.

---

### 2. Order Result Query — Webhook vs Polling

**Primary strategy: Webhook (push)**
- Register `webhookUrl` (QR Payment) or `notify_url` (Recurring Payments) when creating orders
- Process results asynchronously; respond `success` immediately
- Use `notifyId` / `payId` for deduplication

**Fallback strategy: Active polling**

```
# QR Payment polling (when webhook is delayed)
Recommended interval: every 2–3 seconds
Max wait: up to order expiry (max 1 hour)
Stop on: PAY_SUCCESS, PAY_FAILED, TIMEOUT, REFUND_SUCCESS

GET /v5/bybitpay/pay_result?merchantId=...&paymentType=E_COMMERCE&payId={payId}

# Recurring Payments polling (after PROCESSING status or request timeout)
Recommended interval: every 3–5 seconds
Max attempts: 10 times
Stop on: SUCCESS, FAILED, TIMEOUT

GET /v5/bybitpay/agreement/pay/query?merchant_id=...&trade_no={trade_no}
```

**Decision logic:**
```
On API call timeout (30s) → query once immediately → if PROCESSING → poll
On webhook not received within N seconds → trigger active poll
```

---

### 3. Idempotency — Ensuring Transaction Uniqueness

| Scenario | Idempotency Key | Behavior |
|:---------|:----------------|:---------|
| QR Payment create | `merchantTradeNo` | Same `merchantTradeNo` returns same order |
| QR Payment refund | `merchantRefundNo` | Same `merchantRefundNo` returns same refund |
| Recurring sign | `external_agreement_no` | Same value returns existing sign request |
| Recurring deduction | `out_trade_no` | Same `out_trade_no` returns first result |
| Recurring refund | `out_refund_no` | Same `out_refund_no` returns first result |

**Rules:**
- Generate idempotency keys **before** sending the request; store them persistently
- After the **first** request fails: use a **new** key to retry (different from original failure)
- After a request **times out**: query first — if already succeeded, do NOT retry with the same key
- Never reuse order numbers across different orders

```python
# Safe retry pattern for deduction
def safe_deduct(agreement_no, amount, existing_trade_no=None):
    trade_no = existing_trade_no or generate_unique_trade_no()
    try:
        result = call_deduction_api(agreement_no, amount, trade_no)
        if result.status == "PROCESSING":
            return poll_until_final(trade_no)
        return result
    except TimeoutError:
        # Query first before deciding to retry
        existing = query_transaction(trade_no)
        if existing:
            return existing   # already submitted, do NOT create new
        # Only retry with new trade_no if truly not found
        return safe_deduct(agreement_no, amount, generate_unique_trade_no())
```

---

### 4. Risk & Security — Device and IP Information

Provide risk context in every payment/deduction request. This helps pass Bybit's risk control and reduces false rejections.

#### QR Payment — `env` (required) + `riskInfo` (recommended)

```json
{
  "env": {
    "terminalType": "WEB",        // APP | WEB | WAP | MINIAPP | OTHERS
    "device": "Mozilla/5.0 ...",  // device UA or device model (e.g. iPhone15,2)
    "browserVersion": "Chrome/133.0.0.0",
    "ip": "203.0.113.50"          // real user IP, not server IP
  },
  "riskInfo": {
    "terminalType": "WEB"
  }
}
```

#### Recurring Payments Deduction — `scene_info` + `risk_info` (recommended)

```json
{
  "scene_info": {
    "device_id": "device-fingerprint-abc123",
    "device_ip": "203.0.113.50",
    "location": {
      "latitude": "39.9042",
      "longitude": "116.4074",
      "address": "Beijing, China"
    }
  },
  "risk_info": {
    "user_ip": "203.0.113.50",
    "device_fingerprint": "fp_abc123xyz",
    "user_agent": "Mozilla/5.0 ..."
  }
}
```

**Key rules:**
- Always pass the **real end-user IP**, not your backend server IP
- For mobile apps: use device model as `device` (e.g., `iPhone15,2`, `Pixel 8`)
- For ride-hailing/parking: include GPS `location` in `scene_info`
- If risk control rejects (`RISK_REJECT` / `139005001`): guide user to complete active payment with identity verification

---

### 5. Common Error Handling

#### QR Payment Error Codes

| Code | Meaning | Action |
|:-----|:--------|:-------|
| `100000` | Success | — |
| `400000` | Invalid parameters | Check request fields |
| `400002` | Signature failed | Verify sign algorithm & key |
| `400003` | Timestamp timeout | Sync server clock |
| `400620` | Duplicate order number | Use unique `merchantTradeNo` |
| `500008` | Merchant not found | Check `merchantId` |
| `500100` | QR code expired | Create a new order |
| `500104` | Refund balance unavailable | Top up KYB funding account |
| `500105` | Order not paid | Cannot refund unpaid order |
| `500000` | Bybit internal error | Retry with exponential backoff |

#### Recurring Payments Error Codes

| Code | Meaning | Action |
|:-----|:--------|:-------|
| `20000` | Success | — |
| `139001001` | Agreement not found | Check agreement number |
| `139001002` | Agreement expired | Re-sign |
| `139001003` | Agreement unsigned | Re-sign |
| `139001012` | Sign URL expired | Re-call sign request API |
| `139002002` | Quota exceeded | Notify user; wait for reset |
| `139002003` | Insufficient balance | Notify user to top up |
| `139002005` | Trade processing | Wait; do NOT retry with same `out_trade_no` |
| `139004005` | Exceeds single limit | Lower amount or adjust limit |
| `139005001` | Risk rejected | Guide to active payment |
| `139005002` | Invalid signature | Check sign algorithm |
| `139005003` | Timestamp invalid | Must be within 5 minutes of server time |
| `50000`–`50002` | System error | Retry with exponential backoff |

**Retryable errors:** `50000`, `50001`, `50002`, `139002005`, `139003003`
**Non-retryable:** All `139001xxx`, `139002001`–`139002004`, `139003001`–`139003002`

---

## Agreement Type Quick Reference

| Type | Deduction Frequency | After First Deduction | Use Case |
|:-----|:-------------------|:----------------------|:---------|
| `CYCLE` | Periodic (fixed schedule) | Remains SIGNED | Subscriptions, monthly bills |
| `NON_CYCLE` | Irregular (any time) | Remains SIGNED | Ride-hailing, parking, food delivery |
| `SINGLE` | One-time only | Auto UNSIGNED | Deposits, one-time pre-auth |

**Limit support:** CYCLE/NON_CYCLE support `single_limit` + `period_limits` (DAY/WEEK/MONTH/YEAR). SINGLE supports `single_limit` only.

---

## Order Status Reference

### QR Payment Order Status

```
INIT → PAY_SUCCESS → REFUND_SUCCESS
     ↘ PAY_FAILED
     ↘ TIMEOUT
```

### Recurring Payments — Agreement Status

```
INIT → PENDING → SIGNED ⇄ SUSPENDED
              ↘ FAILED
              ↘ TIMEOUT
SIGNED → UNSIGNED (final)
SIGNED → EXPIRED (final)
```

### Recurring Payments — Transaction Status

```
PROCESSING → SUCCESS
           → FAILED
           → TIMEOUT
```

---

## Quick Start Checklist

**QR Payment:**
- [ ] Generate API key at Bybit (testnet first, then mainnet)
- [ ] Implement HMAC_SHA256 or RSA_SHA256 request signing
- [ ] Build `POST /v5/bybitpay/create_pay` with `env.ip` = real user IP
- [ ] Host a public `webhookUrl` endpoint; verify Bybit's RSA signature
- [ ] Store `merchantTradeNo` before calling API (idempotency)
- [ ] Implement polling fallback using `GET /v5/bybitpay/pay_result`

**Recurring Payments:**
- [ ] Call `POST /v5/bybitpay/agreement/sign`; display QR to user
- [ ] Receive `SIGNED` webhook; store `agreement_no`
- [ ] Verify webhook using `X-Timestamp + X-Nonce + rawBody` with platform RSA public key
- [ ] Use unique `out_trade_no` per deduction; store before calling API
- [ ] Handle `PROCESSING` status: wait for webhook, then poll `pay/query`
- [ ] Implement unsign flow for user cancellation
