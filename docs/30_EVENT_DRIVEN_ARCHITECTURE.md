# SAEQ — Event-Driven Architecture

> **Version:** 1.0.0  
> **Status:** Draft  
> **Last Updated:** 2026-07-24  
> **Author:** Senior Flutter Software Engineer  
> **Related:** [12_DELIVERY_ENGINE.md](./12_DELIVERY_ENGINE.md), [13_API_ARCHITECTURE.md](./13_API_ARCHITECTURE.md)

---

## 1. Purpose

This document defines the **event-driven architecture** for the SAEQ platform. Events are the backbone of real-time communication, offline sync, and future microservices migration. Each event has a publisher, subscribers, payload, retry policy, and idempotency strategy.

---

## 2. Event Catalog

| ID | Event | Publisher | Subscribers | Trigger |
|----|-------|-----------|-------------|---------|
| EVT-001 | OrderCreated | Orders API | Driver Matching, Notification, Analytics | Customer creates order |
| EVT-002 | OrderAccepted | Orders API | Customer App, Driver App, Analytics | Driver accepts order |
| EVT-003 | OrderRejected | Orders API | Driver Matching, Notification | Driver rejects order |
| EVT-004 | DriverArrived | Driver App | Orders API, Customer App, Analytics | Driver arrives at pickup |
| EVT-005 | OrderPickedUp | Driver App | Orders API, Customer App, Analytics | Driver confirms pickup |
| EVT-006 | OrderInTransit | Driver App | Orders API, Customer App, Analytics | Driver starts delivery |
| EVT-007 | OrderDelivered | Driver App | Orders API, Payment, Customer App, Analytics | Driver confirms delivery |
| EVT-008 | OrderCancelled | Orders API | Payment, Notification, Analytics | Customer/Admin cancels order |
| EVT-009 | OrderFailed | Driver App | Orders API, Customer App, Analytics | Delivery fails |
| EVT-010 | PaymentCaptured | Payment API | Orders API, Earnings, Notification | Payment processed |
| EVT-011 | PaymentRefunded | Payment API | Orders API, Notification | Refund processed |
| EVT-012 | DriverOnline | Driver App | Driver Matching | Driver goes online |
| EVT-013 | DriverOffline | Driver App | Driver Matching | Driver goes offline |
| EVT-014 | LocationUpdated | Driver App | Customer App, Tracking | GPS location change |
| EVT-015 | NotificationSent | Notification Service | Analytics | Push notification sent |
| EVT-016 | NotificationOpened | Driver/Customer App | Analytics | User opens notification |
| EVT-017 | DocumentUploaded | Driver App | Document Verification | Driver uploads document |
| EVT-018 | DocumentVerified | Admin App | Notification, Driver App | Admin verifies document |
| EVT-019 | DocumentRejected | Admin App | Notification, Driver App | Admin rejects document |
| EVT-020 | SyncStarted | Driver App | Offline Sync Manager | Device comes online |
| EVT-021 | SyncCompleted | Driver App | Offline Sync Manager | Sync queue emptied |
| EVT-022 | SyncFailed | Driver App | Offline Sync Manager | Sync error occurred |
| EVT-023 | ChatMessageSent | Chat API | WebSocket Hub, Notification | User sends message |
| EVT-024 | UserRegistered | Auth API | Analytics, Notification | New user registers |
| EVT-025 | UserLoggedIn | Auth API | Analytics | User logs in |

---

## 3. Event Details

### EVT-001: OrderCreated

| Field | Value |
|-------|-------|
| **Publisher** | Orders API |
| **Subscribers** | Driver Matching Service, Notification Service, Analytics Service |
| **Trigger** | Customer successfully creates an order |

#### Payload

```json
{
  "event_id": "uuid",
  "event_type": "OrderCreated",
  "timestamp": "2026-07-24T10:30:00Z",
  "data": {
    "order_id": "uuid",
    "customer_id": "uuid",
    "pickup": {
      "lat": 24.7136,
      "lng": 46.6753,
      "address": "Riyadh, Olaya District"
    },
    "delivery": {
      "lat": 24.7743,
      "lng": 46.7385,
      "address": "Riyadh, Al Malaz District"
    },
    "order_type": "immediate",
    "total": 45.00,
    "currency": "SAR"
  }
}
```

#### Retry Policy

| Attempt | Delay | Strategy |
|---------|-------|----------|
| 1 | 0s | Immediate |
| 2 | 5s | Fixed |
| 3 | 30s | Fixed |
| 4 | 120s | Fixed |
| 5+ | 300s | Dead letter queue |

#### Idempotency

- Key: `event_id` (UUID v4)
- Duplicate detection: Check if `event_id` already processed
- Action on duplicate: Silently ignore

#### Dead Letter Queue

- Max retries: 5
- DLQ retention: 7 days
- DLQ alert: Notify on-call engineer after 3 failed attempts

---

### EVT-002: OrderAccepted

| Field | Value |
|-------|-------|
| **Publisher** | Orders API |
| **Subscribers** | Customer App (WebSocket), Driver App, Analytics Service |

#### Payload

```json
{
  "event_id": "uuid",
  "event_type": "OrderAccepted",
  "timestamp": "2026-07-24T10:30:05Z",
  "data": {
    "order_id": "uuid",
    "driver_id": "uuid",
    "driver_name": "أحمد محمد",
    "driver_rating": 4.8,
    "vehicle_type": "car",
    "vehicle_color": "white",
    "vehicle_plate": "ABC 1234",
    "estimated_arrival_minutes": 8
  }
}
```

#### Retry Policy

| Attempt | Delay | Strategy |
|---------|-------|----------|
| 1 | 0s | Immediate |
| 2 | 3s | Fixed |
| 3 | 10s | Fixed |

#### Idempotency

- Key: `event_id`
- Duplicate detection: Check if order status already `accepted`
- Action on duplicate: Return current state

---

### EVT-006: OrderInTransit

| Field | Value |
|-------|-------|
| **Publisher** | Driver App |
| **Subscribers** | Orders API, Customer App (WebSocket), Analytics Service |

#### Payload

```json
{
  "event_id": "uuid",
  "event_type": "OrderInTransit",
  "timestamp": "2026-07-24T10:45:00Z",
  "data": {
    "order_id": "uuid",
    "driver_id": "uuid",
    "pickup_confirmed_at": "2026-07-24T10:40:00Z",
    "current_location": {
      "lat": 24.7300,
      "lng": 46.7000
    },
    "eta_minutes": 12
  }
}
```

---

### EVT-010: PaymentCaptured

| Field | Value |
|-------|-------|
| **Publisher** | Payment API |
| **Subscribers** | Orders API, Earnings Service, Notification Service, Analytics Service |

#### Payload

```json
{
  "event_id": "uuid",
  "event_type": "PaymentCaptured",
  "timestamp": "2026-07-24T10:50:00Z",
  "data": {
    "payment_id": "uuid",
    "order_id": "uuid",
    "customer_id": "uuid",
    "driver_id": "uuid",
    "amount": 45.00,
    "fee": 4.50,
    "net_amount": 40.50,
    "currency": "SAR",
    "method": "card",
    "gateway_reference": "txn_abc123"
  }
}
```

---

### EVT-014: LocationUpdated

| Field | Value |
|-------|-------|
| **Publisher** | Driver App |
| **Subscribers** | Customer App (WebSocket), Tracking Service |
| **Frequency** | Every 5 seconds when driver is online and on delivery |

#### Payload

```json
{
  "event_id": "uuid",
  "event_type": "LocationUpdated",
  "timestamp": "2026-07-24T10:30:05Z",
  "data": {
    "driver_id": "uuid",
    "order_id": "uuid",
    "lat": 24.7136,
    "lng": 46.6753,
    "bearing": 180.5,
    "speed_kmh": 45.0,
    "accuracy_meters": 8.0
  }
}
```

#### Throttling

- Maximum 1 event per 5 seconds per driver
- If network is slow, batch last known location

---

### EVT-020: SyncStarted

| Field | Value |
|-------|-------|
| **Publisher** | Driver App (Offline Sync Manager) |
| **Subscribers** | Local storage, UI state |

#### Payload

```json
{
  "event_id": "uuid",
  "event_type": "SyncStarted",
  "timestamp": "2026-07-24T11:00:00Z",
  "data": {
    "device_id": "uuid",
    "pending_actions": 15,
    "last_sync_at": "2026-07-24T10:00:00Z"
  }
}
```

---

## 4. Event Ordering

| Stream | Ordering Key | Ordering Guarantee |
|--------|-------------|-------------------|
| Order events | `order_id` | Strict ordering per order |
| Driver events | `driver_id` | Strict ordering per driver |
| Payment events | `payment_id` | Strict ordering per payment |
| Location updates | `driver_id` | Last-write-wins (no ordering needed) |
| Notifications | `user_id` | Best effort ordering |

---

## 5. Dead Letter Queue (DLQ) Configuration

| Queue | Max Retries | Retention | Alert Threshold | Alert Method |
|-------|-------------|-----------|-----------------|--------------|
| Orders DLQ | 5 | 7 days | 3 failed attempts | Email + Slack |
| Payments DLQ | 10 | 14 days | 5 failed attempts | Email + SMS |
| Notifications DLQ | 3 | 3 days | 10 failed attempts | Email |
| Location DLQ | 2 | 1 day | 100 failed attempts | Email (daily digest) |

---

## 6. Event Flow Diagrams

### 6.1 Order Lifecycle Events

```
OrderCreated → OrderAccepted → DriverArrived → OrderPickedUp → OrderInTransit → OrderDelivered → PaymentCaptured
     ↓               ↓               ↓               ↓               ↓               ↓               ↓
  (rejected)     (cancelled)     (cancelled)     (cancelled)     (cancelled)     (failed)        (refunded)
```

### 6.2 Driver Lifecycle Events

```
DriverOnline → LocationUpdated (repeating) → DriverOffline
     ↓
  (busy during delivery)
```

### 6.3 Document Lifecycle Events

```
DocumentUploaded → DocumentVerified → (notification sent)
                 → DocumentRejected → (notification sent)
```

---

*This document defines the event-driven architecture for the SAEQ platform. Events are the foundation for real-time features and future microservices migration.*