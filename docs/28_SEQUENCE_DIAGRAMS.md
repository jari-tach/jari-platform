# SAEQ — Sequence Diagrams

> **Version:** 1.0.0  
> **Status:** Draft  
> **Last Updated:** 2026-07-24  
> **Author:** Senior Flutter Software Engineer  
> **Related:** [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md), [12_DELIVERY_ENGINE.md](./12_DELIVERY_ENGINE.md)

---

## 1. Purpose

This document contains **UML Sequence Diagrams** for the SAEQ platform. These diagrams are essential for developers to understand the flow of interactions between components. No theoretical explanations are included — only executable interaction flows.

---

## 2. Diagram Key

```
Actor        System        Component        External
  |             |              |               |
  |--- action ->|              |               |
  |             |--- request ->|               |
  |             |              |--- call ------>|
  |             |              |<- response ----|
  |             |<- result ----|               |
  |<- display --|              |               |
```

---

## 3. UC-001: Login (Email/Password)

```
Driver App                Auth API               Token Service           Local Storage
    |                        |                        |                       |
    |-- POST /auth/login --->|                        |                       |
    |   {email, password}    |                        |                       |
    |                        |-- validate credentials |                       |
    |                        |                        |                       |
    |                        |-- generate JWT ------->|                       |
    |                        |<- {access,refresh} ----|                       |
    |                        |                        |                       |
    |<- 200 {tokens, user} --|                        |                       |
    |                        |                        |                       |
    |-- store tokens ------->|                        |                       |
    |                        |                        |-- save securely ----->|
    |                        |                        |                       |
    |-- navigate to home ---|                        |                       |
```

---

## 4. UC-002: Create Order

```
Customer App             Orders API              Driver Matching           Payment Gateway
    |                        |                        |                        |
    |-- POST /orders ------->|                        |                        |
    |   {pickup, delivery,   |                        |                        |
    |    items, payment}     |                        |                        |
    |                        |                        |                        |
    |                        |-- validate addresses ->|                        |
    |                        |<- valid ---------------|                        |
    |                        |                        |                        |
    |                        |-- charge amount ------>|                        |
    |                        |                        |--- call --------------->|
    |                        |                        |<- response ------------|
    |                        |                        |                        |
    |                        |-- find nearest driver ->|                       |
    |                        |<- driver_id -----------|                        |
    |                        |                        |                        |
    |                        |-- create order --------|                       |
    |<- 201 {order_id} ------|                        |                        |
    |                        |                        |                        |
    |                        |-- notify driver ------>|                        |
    |                        |   (push notification)  |                        |
```

---

## 5. UC-003: Accept Order

```
Driver App              Orders API              Customer App              WebSocket
    |                       |                        |                        |
    |<-- new order notification (WebSocket) ---------|                        |
    |                       |                        |                        |
    |-- POST /orders/{id} -->|                       |                        |
    |   /accept             |                        |                        |
    |                       |-- validate driver ---->|                       |
    |<- 200 {status} -------|                        |                        |
    |                       |                        |                        |
    |                       |-- broadcast update --->|                        |
    |                       |   (WebSocket)          |                        |
    |                       |                        |<- display status ------|
    |                       |                        |                        |
    |-- navigate to pickup -|                        |                        |
```

---

## 6. UC-004: Driver Tracking

```
Driver App (GPS)        Location API            WebSocket Server        Customer App
    |                       |                        |                       |
    |-- PUT /driver/location|->                      |                       |
    |   {lat, lng, bearing} |                        |                       |
    |                       |-- broadcast location ->|                       |
    |                       |                        |-- push to customer -->|
    |                       |                        |   {lat, lng, bearing} |
    |                       |                        |                       |
    |                       |                        |-- update map -------->|
    |                       |                        |                       |
    |-- (repeat every 5s) -|->                      |                       |
```

---

## 7. UC-005: OTP Verification

```
Driver App                Auth API               SMS Gateway
    |                        |                        |
    |-- POST /auth/otp ------>|                       |
    |   {phone}              |                        |
    |                        |-- generate OTP ------->|
    |                        |                        |
    |                        |-- send SMS ----------->|
    |<- 200 {otp_id} --------|                        |
    |                        |                        |
    |-- POST /auth/verify --->|                       |
    |   {otp_id, otp_code}   |                        |
    |                        |-- validate OTP ------->|
    |                        |                        |
    |<- 200 {tokens} --------|                        |
```

---

## 8. UC-006: Offline Sync

```
Driver App (Offline)     Local Queue             Sync Manager            Orders API
    |                        |                        |                       |
    |-- action performed --->|                        |                       |
    |   (status update)      |-- enqueue action ----->|                       |
    |                        |                        |                       |
    | [connectivity restored]|                        |                       |
    |                        |                        |                       |
    |                        |-- trigger sync ------->|                       |
    |                        |                        |                       |
    |                        |-- dequeue action ----->|                       |
    |                        |                        |-- POST /sync -------->|
    |                        |                        |   {actions}           |
    |                        |                        |                       |
    |                        |                        |<- 200 {results} ------|
    |                        |                        |                       |
    |                        |-- mark as synced ----->|                       |
    |                        |                        |                       |
    |                        | [next action]          |                       |
    |                        |                        |                       |
    |                        |-- dequeue action ----->|                       |
    |                        |                        |-- POST /sync -------->|
    |                        |                        |<- 200 {results} ------|
    |                        |                        |                       |
    |                        |-- mark as synced ----->|                       |
```

---

## 9. UC-007: Payment Processing

```
Driver App                Payment API             Payment Gateway         Banking API
    |                        |                        |                       |
    |-- complete delivery --->|                       |                       |
    |                        |                        |                       |
    |                        |-- capture payment ---->|                       |
    |                        |   {payment_intent_id}  |                       |
    |                        |                        |-- process charge ---->|
    |                        |                        |<- success -----------|
    |                        |                        |                       |
    |                        |-- create receipt ----->|                       |
    |<- 200 {receipt_url} ---|                        |                       |
    |                        |                        |                       |
    |                        |-- calculate earnings ->|                       |
    |                        |   {order_total - fees} |                       |
```

---

## 10. UC-008: Push Notification

```
Server Event             Notification Service       FCM/APNs               Driver App
    |                        |                        |                       |
    |-- new order ---------->|                        |                       |
    |                        |                        |                       |
    |                        |-- build payload ------>|                       |
    |                        |   {title, body, data}  |                       |
    |                        |                        |                       |
    |                        |-- send push ---------->|                       |
    |                        |                        |                       |
    |                        |                        |-- deliver ----------->|
    |                        |                        |   (FCM or APNs)       |
    |                        |                        |                       |
    |                        |                        |-- display notification|
    |                        |                        |                       |
    |                        |-- track delivery ----->|                       |
    |                        |<- confirmed -----------|                       |
```

---

## 11. UC-009: Driver-Customer Chat

```
Driver App                Chat API                WebSocket Hub           Customer App
    |                        |                        |                       |
    |-- POST /chat/message ->|                        |                       |
    |   {order_id, text}     |                        |                       |
    |                        |                        |                       |
    |                        |-- store message ------>|                       |
    |                        |                        |                       |
    |                        |-- broadcast ---------->|                       |
    |                        |   (WebSocket)          |-- deliver message --->|
    |                        |                        |                       |
    |                        |                        |-- display message --->|
    |                        |                        |                       |
    |                        |-- push notification -->|                       |
    |                        |   (if offline)         |                       |
```

---

## 12. UC-010: Upload Document

```
Driver App                Document API            Storage Service (S3)    Verification Service
    |                        |                        |                        |
    |-- POST /documents ---->|                        |                        |
    |   {type, file}         |                        |                        |
    |                        |                        |                        |
    |                        |-- generate presigned -->|                       |
    |                        |   upload URL            |                        |
    |<- 200 {upload_url} ----|                        |                        |
    |                        |                        |                        |
    |-- PUT {upload_url} --->|                        |                        |
    |   (binary file data)   |                        |                        |
    |                        |-- store file --------->|                        |
    |                        |<- 200 {file_url} ------|                        |
    |                        |                        |                        |
    |-- POST /documents ---->|                        |                        |
    |   /verify {file_url}   |                        |                        |
    |                        |                        |                        |
    |                        |-- send for OCR ------->|                        |
    |                        |                        |-- validate document -->|
    |                        |                        |<- verified/rejected ---|
    |                        |                        |                        |
    |<- 200 {status} --------|                        |                        |
```

---

## 13. UC-011: Order State Machine

```
                     +-----------+
                     | PENDING   |
                     +-----+-----+
                           |
                     +-----v-----+
                     | ACCEPTED  |
                     +-----+-----+
                           |
                     +-----v-----+
                     | ARRIVED   |
                     | (at pickup)|
                     +-----+-----+
                           |
                     +-----v-----+
                     | PICKED_UP |
                     +-----+-----+
                           |
                     +-----v-----+
                     | IN_TRANSIT|
                     +-----+-----+
                           |
                     +-----v-----+
                     | DELIVERED |
                     +-----+-----+
                           |
               +-----------+-----------+
               |                       |
         +-----v-----+          +------v----+
         | COMPLETED  |          | FAILED    |
         +-----------+          +-----------+
```

---

*This document contains only sequence diagrams for the SAEQ platform. Refer to [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md) for endpoint details.*