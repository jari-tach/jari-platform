# SAEQ — Data Dictionary

> **Version:** 1.0.0  
> **Status:** Draft  
> **Last Updated:** 2026-07-24  
> **Author:** Senior Flutter Software Engineer  
> **Related:** [09_DATABASE_ARCHITECTURE.md](./09_DATABASE_ARCHITECTURE.md)

---

## 1. Purpose

This document is the **complete data dictionary** for the SAEQ platform. It describes every field in the system, including type, values, description, rules, where it is used, who modifies it, and who reads it. This is not a database schema — it is a business-level definition of all data elements.

---

## 2. Entity: User

| Field | Type | Values | Description | Rules | Used In | Written By | Read By |
|-------|------|--------|-------------|-------|---------|------------|---------|
| id | UUID | - | Unique user identifier | Auto-generated | All systems | System | All |
| email | String | - | User email address | Must be valid email format, unique | Auth, Profile | User | User, Admin |
| phone | String | - | Phone number with country code | Must be valid Saudi number (05xxxxxxxx) | Auth, Profile | User | User, Admin |
| password_hash | String | - | Bcrypt hash of password | Never exposed to client | Auth | System | Auth only |
| role | Enum | driver, customer, admin | User role | Cannot be changed after creation | Auth, RBAC | System, Admin | All |
| status | Enum | active, suspended, inactive | Account status | Admin can suspend | All | Admin, System | All |
| name_ar | String | - | Full name in Arabic | Required for Saudi users | Profile | User | User, Admin |
| name_en | String | - | Full name in English | Optional | Profile | User | User, Admin |
| avatar_url | String? | - | Profile picture URL | Max 5MB, JPEG/PNG | Profile | User | All |
| created_at | DateTime | - | Account creation timestamp | Auto-generated | All | System | All |
| updated_at | DateTime | - | Last update timestamp | Auto-updated | All | System | All |
| last_login_at | DateTime? | - | Last successful login | Updated on each login | Auth | System | Admin |
| email_verified | Boolean | true, false | Email verification status | Default false | Auth | System | Auth |
| phone_verified | Boolean | true, false | Phone verification status | Default false | Auth | System | Auth |
| locale | String | ar, en | User language preference | Default 'ar' | App | User | App |

---

## 3. Entity: Driver

| Field | Type | Values | Description | Rules | Used In | Written By | Read By |
|-------|------|--------|-------------|-------|---------|------------|---------|
| id | UUID | - | Driver identifier (links to user.id) | Unique, mandatory | All driver features | System | All |
| user_id | UUID | - | FK to User | Mandatory | Profile | System | All |
| status | Enum | online, offline, busy, inactive | Driver availability | Only 'online' can receive orders | Orders, Driver | Driver, System | All |
| vehicle_type | Enum | car, motorcycle, truck, bicycle | Type of vehicle | Mandatory for drivers | Profile, Orders | Driver | Driver, Admin |
| vehicle_model | String | - | Vehicle make and model | Max 100 chars | Profile | Driver | Driver, Admin |
| vehicle_plate | String | - | Saudi vehicle plate number | Must match Saudi format | Profile | Driver | Driver, Admin |
| vehicle_color | String | - | Vehicle color | Max 50 chars | Profile | Driver | Driver, Admin |
| license_number | String | - | Driver's license number | Unique, encrypted | Documents | Driver | Admin |
| license_expiry | DateTime | - | License expiry date | System sends notification before expiry | Documents | Driver | System, Admin |
| current_lat | Double? | -90 to 90 | Current latitude | Updated every 5s when online | Tracking | System | Customer, Admin |
| current_lng | Double? | -180 to 180 | Current longitude | Updated every 5s when online | Tracking | System | Customer, Admin |
| current_bearing | Double? | 0 to 360 | Current bearing/direction | Updated every 5s when online | Tracking | System | Customer |
| total_deliveries | Integer | - | Lifetime delivery count | Calculated by system | Profile | System | Driver, Admin |
| total_earnings | Decimal | - | Lifetime earnings | Calculated by system | Earnings | System | Driver, Admin |
| rating | Decimal | 1.0 to 5.0 | Average driver rating | Calculated from reviews | Profile, Orders | System | All |
| rating_count | Integer | - | Number of ratings received | Incremented with each review | Profile | System | All |
| is_verified | Boolean | true, false | Document verification status | Admin must verify all documents | Orders | Admin | All |
| joined_at | DateTime | - | When driver joined platform | Auto-generated | Profile | System | All |

---

## 4. Entity: Customer

| Field | Type | Values | Description | Rules | Used In | Written By | Read By |
|-------|------|--------|-------------|-------|---------|------------|---------|
| id | UUID | - | Customer identifier (links to user.id) | Unique, mandatory | All customer features | System | All |
| user_id | UUID | - | FK to User | Mandatory | Profile | System | All |
| default_address_id | UUID? | - | Default delivery address | Optional | Orders | Customer | Customer, System |
| total_orders | Integer | - | Lifetime order count | Calculated by system | Profile | System | Customer, Admin |
| total_spent | Decimal | - | Lifetime total spend | Calculated by system | Profile | System | Customer, Admin |

---

## 5. Entity: Order

| Field | Type | Values | Description | Rules | Used In | Written By | Read By |
|-------|------|--------|-------------|-------|---------|------------|---------|
| id | UUID | - | Order identifier | Auto-generated | All | System | All |
| customer_id | UUID | - | FK to Customer | Mandatory | Orders | System | Customer, Driver, Admin |
| driver_id | UUID? | - | FK to Driver (assigned) | Set when driver accepts | Orders | System | All |
| status | Enum | pending, accepted, arrived, picked_up, in_transit, delivered, completed, failed, cancelled | Current order status | State machine enforced | Orders | System, Driver | All |
| pickup_address | JSON | - | {building, street, district, city, lat, lng} | Structured Saudi address | Orders | Customer | All |
| delivery_address | JSON | - | {building, street, district, city, lat, lng} | Structured Saudi address | Orders | Customer | All |
| pickup_notes | String? | - | Special instructions for pickup | Max 500 chars | Orders | Customer | Driver |
| delivery_notes | String? | - | Special instructions for delivery | Max 500 chars | Orders | Customer | Driver |
| order_type | Enum | immediate, scheduled, wholesale | Type of order | Affects assignment logic | Orders | Customer | All |
| scheduled_at | DateTime? | - | For scheduled orders | Required if type=scheduled | Orders | Customer | All, Driver |
| items | JSON[] | - | Array of order items | See OrderItem entity | Orders | Customer | All |
| subtotal | Decimal | - | Sum of item prices | Calculated | Payment | System | All |
| delivery_fee | Decimal | - | Delivery service fee | Configurable | Payment | System, Admin | All |
| service_fee | Decimal | - | Platform service fee | Percentage of subtotal | Payment | System | Admin |
| total | Decimal | - | subtotal + delivery_fee + service_fee | Calculated | Payment | System | All |
| payment_method | Enum | card, wallet, cash, mada | Payment method | Selected by customer | Payment | Customer | All |
| payment_status | Enum | pending, authorized, captured, refunded, failed | Payment processing status | Updated by payment gateway | Payment | System, Gateway | All |
| payment_intent_id | String? | - | Payment gateway reference ID | From payment gateway | Payment | System | Admin |
| otp_code | String? | - | Delivery confirmation code | 6-digit, expires in 5 min | Orders | System | Driver |
| otp_expires_at | DateTime? | - | OTP expiry time | Auto-set when generated | Orders | System | System |
| cancelled_at | DateTime? | - | When order was cancelled | Set on cancellation | Orders | System | All |
| cancel_reason | String? | - | Reason for cancellation | Max 300 chars | Orders | User | Admin |
| completed_at | DateTime? | - | When delivery was completed | Set when status=completed | Orders | System | All |
| created_at | DateTime | - | Order creation timestamp | Auto-generated | All | System | All |
| updated_at | DateTime | - | Last update timestamp | Auto-updated | All | System | All |

---

## 6. Entity: OrderItem

| Field | Type | Values | Description | Rules | Used In | Written By | Read By |
|-------|------|--------|-------------|-------|---------|------------|---------|
| id | UUID | - | Item identifier | Auto-generated | Orders | System | All |
| order_id | UUID | - | FK to Order | Mandatory | Orders | System | All |
| name_ar | String | - | Item name in Arabic | Mandatory | Orders | Customer | All |
| name_en | String? | - | Item name in English | Optional | Orders | Customer | All |
| quantity | Integer | 1+ | Number of units | Min 1, max 100 | Orders | Customer | All |
| unit_price | Decimal | - | Price per unit | Must be >= 0 | Orders | Customer | All |
| total_price | Decimal | - | quantity * unit_price | Calculated | Orders | System | All |
| notes | String? | - | Item-specific instructions | Max 200 chars | Orders | Customer | Driver |

---

## 7. Entity: Payment

| Field | Type | Values | Description | Rules | Used In | Written By | Read By |
|-------|------|--------|-------------|-------|---------|------------|---------|
| id | UUID | - | Payment identifier | Auto-generated | Payment | System | Admin |
| order_id | UUID | - | FK to Order | Mandatory | Payment | System | Admin |
| customer_id | UUID | - | FK to Customer | Mandatory | Payment | System | Admin |
| driver_id | UUID? | - | FK to Driver (for earnings) | Set when order completed | Payment | System | Driver, Admin |
| amount | Decimal | - | Payment amount | Must match order.total | Payment | System | Admin |
| fee | Decimal | - | Platform fee | Percentage of amount | Payment | System | Admin |
| net_amount | Decimal | - | amount - fee (driver earnings) | Calculated | Payment | System | Driver, Admin |
| currency | String | SAR | Currency code | Only SAR supported | Payment | System | All |
| method | Enum | card, wallet, cash, mada | Payment method | Selected by customer | Payment | Customer | All |
| status | Enum | pending, authorized, captured, refunded, failed, partially_refunded | Payment status | Updated by gateway | Payment | System, Gateway | All |
| gateway_reference | String? | - | Payment gateway transaction ID | From gateway | Payment | System | Admin |
| gateway_response | JSON? | - | Full gateway response | For debugging | Payment | System | Admin only |
| receipt_url | String? | - | URL to generated receipt | Generated on capture | Payment | System | Customer, Admin |
| captured_at | DateTime? | - | When payment was captured | Set on delivery complete | Payment | System | Admin |
| refunded_at | DateTime? | - | When refund was processed | Set on refund | Payment | System | Admin |
| created_at | DateTime | - | Payment record creation | Auto-generated | Payment | System | Admin |

---

## 8. Entity: Notification

| Field | Type | Values | Description | Rules | Used In | Written By | Read By |
|-------|------|--------|-------------|-------|---------|------------|---------|
| id | UUID | - | Notification identifier | Auto-generated | Notifications | System | User |
| user_id | UUID | - | FK to User (recipient) | Mandatory | Notifications | System | User |
| type | Enum | new_order, order_accepted, order_status, payment_receipt, document_verified, system | Notification type | Defines icon and behavior | Notifications | System | User |
| title | String | - | Notification title | Localized | Notifications | System | User |
| body | String | - | Notification body | Localized | Notifications | System | User |
| data | JSON? | - | Additional payload (e.g., order_id) | Used for deep linking | Notifications | System | App |
| is_read | Boolean | true, false | Read status | Default false | Notifications | User | User, System |
| push_sent | Boolean | true, false | Push notification delivered | Tracked by FCM/APNs | Notifications | System | Admin |
| push_read_at | DateTime? | - | When push was opened | From FCM/APNs analytics | Notifications | System | Admin |
| created_at | DateTime | - | Notification creation | Auto-generated | Notifications | System | User |

---

## 9. Entity: Document

| Field | Type | Values | Description | Rules | Used In | Written By | Read By |
|-------|------|--------|-------------|-------|---------|------------|---------|
| id | UUID | - | Document identifier | Auto-generated | Documents | System | User, Admin |
| user_id | UUID | - | FK to User (owner) | Mandatory | Documents | User | User, Admin |
| type | Enum | national_id, driver_license, vehicle_registration, insurance, commercial_register, other | Document type | Defines verification rules | Documents | User | Admin, System |
| file_url | String | - | Document file URL | Stored in S3/CDN | Documents | System | User, Admin |
| file_size | Integer | - | File size in bytes | Max 10MB | Documents | System | Admin |
| mime_type | String | - | File MIME type | PDF, JPEG, PNG | Documents | System | Admin |
| status | Enum | pending, verified, rejected, expired | Verification status | Admin reviews | Documents | Admin | All |
| rejection_reason | String? | - | Reason if rejected | Max 500 chars | Documents | Admin | User |
| verified_by | UUID? | - | FK to Admin who verified | Set on verification | Documents | Admin | Admin |
| verified_at | DateTime? | - | When verification was done | Set on verify/reject | Documents | System | Admin |
| expires_at | DateTime? | - | Document expiry date | For licenses, IDs, insurance | Documents | System | User, Admin |
| created_at | DateTime | - | Upload timestamp | Auto-generated | Documents | System | All |
| updated_at | DateTime | - | Last update timestamp | Auto-updated | Documents | System | All |

---

## 10. Entity: Trip

| Field | Type | Values | Description | Rules | Used In | Written By | Read By |
|-------|------|--------|-------------|-------|---------|------------|---------|
| id | UUID | - | Trip identifier | Auto-generated | Delivery | System | All |
| order_id | UUID | - | FK to Order | Mandatory | Delivery | System | All |
| driver_id | UUID | - | FK to Driver | Mandatory | Delivery | System | All |
| status | Enum | assigned, to_pickup, at_pickup, to_delivery, at_delivery, completed, failed | Trip status | Mirrors order status | Delivery | System, Driver | All |
| pickup_arrived_at | DateTime? | - | When driver arrived at pickup | GPS geofence trigger | Delivery | System | All |
| pickup_confirmed_at | DateTime? | - | When pickup was confirmed | Driver action | Delivery | Driver | All |
| delivery_arrived_at | DateTime? | - | When driver arrived at delivery | GPS geofence trigger | Delivery | System | All |
| delivery_confirmed_at | DateTime? | - | When delivery was confirmed | Driver action with OTP/photo | Delivery | Driver | All |
| distance_km | Double | - | Estimated trip distance | From map API | Delivery | System | All |
| duration_minutes | Integer | - | Estimated trip duration | From map API | Delivery | System | All |
| actual_distance_km | Double? | - | Actual distance driven | GPS tracking | Delivery | System | Admin |
| actual_duration_minutes | Integer? | - | Actual time taken | Calculated | Delivery | System | Admin |
| started_at | DateTime | - | When trip started (accepted) | Auto-generated | Delivery | System | All |
| completed_at | DateTime? | - | When trip completed | Set when delivered | Delivery | System | All |

---

## 11. Entity: Review

| Field | Type | Values | Description | Rules | Used In | Written By | Read By |
|-------|------|--------|-------------|-------|---------|------------|---------|
| id | UUID | - | Review identifier | Auto-generated | Reviews | System | All |
| order_id | UUID | - | FK to Order | One review per order | Reviews | System | All |
| customer_id | UUID | - | FK to Customer (reviewer) | Mandatory | Reviews | Customer | All |
| driver_id | UUID | - | FK to Driver (reviewee) | Mandatory | Reviews | System | Driver, Admin |
| rating | Integer | 1 to 5 | Star rating | Required | Reviews | Customer | All |
| comment | String? | - | Review text | Max 1000 chars | Reviews | Customer | All |
| created_at | DateTime | - | Review creation | Auto-generated | Reviews | System | All |

---

## 12. Entity: AuditLog

| Field | Type | Values | Description | Rules | Used In | Written By | Read By |
|-------|------|--------|-------------|-------|---------|------------|---------|
| id | UUID | - | Log identifier | Auto-generated | Audit | System | Admin |
| user_id | UUID? | - | FK to User who performed action | Null for system actions | Audit | System | Admin |
| action | String | - | Action performed (e.g., ORDER_CREATED, USER_LOGIN) | Standardized | Audit | System | Admin |
| entity_type | String | - | Entity affected (e.g., order, user, payment) | Standardized | Audit | System | Admin |
| entity_id | UUID? | - | ID of the affected entity | Optional | Audit | System | Admin |
| old_values | JSON? | - | Previous state of the entity | For updates | Audit | System | Admin |
| new_values | JSON? | - | New state of the entity | For updates/creates | Audit | System | Admin |
| ip_address | String? | - | Client IP address | From request | Audit | System | Admin |
| user_agent | String? | - | Client user agent | From request | Audit | System | Admin |
| created_at | DateTime | - | Log creation | Auto-generated | Audit | System | Admin |

---

*This data dictionary is the authoritative reference for all data elements in the SAEQ platform.*