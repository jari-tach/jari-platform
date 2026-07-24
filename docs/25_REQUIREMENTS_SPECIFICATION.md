# SAEQ — Requirements Specification

> **Version:** 1.0.0  
> **Status:** Draft  
> **Last Updated:** 2026-07-24  
> **Author:** Senior Flutter Software Engineer  
> **Related:** [00_PROJECT_BIBLE.md](./00_PROJECT_BIBLE.md), [01_BUSINESS_VISION.md](./01_BUSINESS_VISION.md)

---

## 1. Purpose

This document is the **official source of truth** for all system requirements. It defines **what** the system must do, not **how** it will be implemented. It serves as the contract between stakeholders and the development team.

---

## 2. Business Requirements (BR)

| ID | Requirement | Priority | Source |
|----|-------------|----------|--------|
| BR-001 | Provide a platform connecting customers with delivery drivers | Critical | Business Vision |
| BR-002 | Enable real-time order tracking for customers | High | Market Research |
| BR-003 | Support cashless payments and digital wallets | High | Saudi Vision 2030 |
| BR-004 | Ensure compliance with Saudi regulations (SDAIA, ZATCA) | Critical | Legal |
| BR-005 | Support Arabic and English languages | High | Localization |
| BR-006 | Enable offline operation for drivers in low-connectivity areas | Medium | Field Research |
| BR-007 | Provide earnings reports and analytics for drivers | Medium | Driver Feedback |
| BR-008 | Support multiple order types (immediate, scheduled, wholesale) | High | Business Model |
| BR-009 | Integrate with Saudi map providers for accurate navigation | High | Operational |
| BR-010 | Enable driver document management and verification | Critical | Regulatory |

---

## 3. User Requirements (UR)

### 3.1 Driver Requirements

| ID | Requirement | BR Link |
|----|-------------|---------|
| UR-DRV-001 | Driver can register using email/phone and verify identity | BR-001 |
| UR-DRV-002 | Driver can log in using email/password or biometric authentication | BR-001 |
| UR-DRV-003 | Driver can view available orders in real-time | BR-002 |
| UR-DRV-004 | Driver can accept or reject orders | BR-002 |
| UR-DRV-005 | Driver can navigate to pickup and delivery locations | BR-009 |
| UR-DRV-006 | Driver can update order status (picked up, in transit, delivered) | BR-002 |
| UR-DRV-007 | Driver can view earnings summary (daily, weekly, monthly) | BR-007 |
| UR-DRV-008 | Driver can manage profile and vehicle information | BR-010 |
| UR-DRV-009 | Driver can work offline and sync data when connected | BR-006 |
| UR-DRV-010 | Driver can communicate with customers via in-app chat | BR-001 |
| UR-DRV-011 | Driver can view delivery history | BR-007 |
| UR-DRV-012 | Driver can set availability status (online/offline) | BR-001 |

### 3.2 Customer Requirements

| ID | Requirement | BR Link |
|----|-------------|---------|
| UR-CUS-001 | Customer can create an account and log in | BR-001 |
| UR-CUS-002 | Customer can place an order with pickup and delivery addresses | BR-001 |
| UR-CUS-003 | Customer can track order status in real-time | BR-002 |
| UR-CUS-004 | Customer can make payments using multiple methods | BR-003 |
| UR-CUS-005 | Customer can rate and review deliveries | BR-001 |
| UR-CUS-006 | Customer can view order history | BR-001 |
| UR-CUS-007 | Customer can schedule orders for future delivery | BR-008 |
| UR-CUS-008 | Customer can contact driver via in-app chat | BR-001 |
| UR-CUS-009 | Customer can cancel order within allowed time window | BR-001 |
| UR-CUS-010 | Customer can save favorite addresses | BR-001 |

### 3.3 Admin Requirements

| ID | Requirement | BR Link |
|----|-------------|---------|
| UR-ADM-001 | Admin can view dashboard with key metrics | BR-001 |
| UR-ADM-002 | Admin can manage drivers (approve, suspend, verify documents) | BR-010 |
| UR-ADM-003 | Admin can manage orders and handle disputes | BR-001 |
| UR-ADM-004 | Admin can view financial reports and transactions | BR-007 |
| UR-ADM-005 | Admin can configure system settings and pricing | BR-001 |
| UR-ADM-006 | Admin can manage customer support tickets | BR-001 |
| UR-ADM-007 | Admin can view audit logs for compliance | BR-004 |
| UR-ADM-008 | Admin can manage promotional campaigns | BR-001 |

---

## 4. Functional Requirements (FR)

### 4.1 Authentication & Authorization

| ID | Requirement | UR Link |
|----|-------------|---------|
| FR-AUTH-001 | System shall support email/password authentication | UR-DRV-001, UR-CUS-001 |
| FR-AUTH-002 | System shall support OTP verification via SMS/email | UR-DRV-001 |
| FR-AUTH-003 | System shall support biometric authentication (Face ID, fingerprint) | UR-DRV-002 |
| FR-AUTH-004 | System shall implement JWT-based session management | UR-DRV-002 |
| FR-AUTH-005 | System shall support token refresh mechanism | UR-DRV-002 |
| FR-AUTH-006 | System shall enforce role-based access control (RBAC) | UR-ADM-001 |
| FR-AUTH-007 | System shall lock account after 5 failed login attempts | UR-DRV-002 |
| FR-AUTH-008 | System shall support password reset via email/SMS | UR-DRV-001 |

### 4.2 Order Management

| ID | Requirement | UR Link |
|----|-------------|---------|
| FR-ORD-001 | System shall allow customers to create orders with pickup/delivery addresses | UR-CUS-002 |
| FR-ORD-002 | System shall assign orders to available drivers automatically | UR-DRV-003 |
| FR-ORD-003 | System shall notify drivers of new orders in real-time | UR-DRV-003 |
| FR-ORD-004 | System shall allow drivers to accept/reject orders within time limit | UR-DRV-004 |
| FR-ORD-005 | System shall track order status through defined state machine | UR-DRV-006 |
| FR-ORD-006 | System shall support order cancellation with refund logic | UR-CUS-009 |
| FR-ORD-007 | System shall support scheduled orders | UR-CUS-007 |
| FR-ORD-008 | System shall provide order history with filtering and search | UR-CUS-006, UR-DRV-011 |

### 4.3 Payment Processing

| ID | Requirement | UR Link |
|----|-------------|---------|
| FR-PAY-001 | System shall support multiple payment methods (card, wallet, cash) | UR-CUS-004 |
| FR-PAY-002 | System shall process payments securely via PCI-compliant gateway | UR-CUS-004 |
| FR-PAY-003 | System shall support automatic payment capture on delivery | UR-CUS-004 |
| FR-PAY-004 | System shall handle refunds and chargebacks | UR-CUS-009 |
| FR-PAY-005 | System shall calculate and display driver earnings | UR-DRV-007 |
| FR-PAY-006 | System shall support driver payout requests | UR-DRV-007 |
| FR-PAY-007 | System shall generate payment receipts and invoices | UR-CUS-004 |

### 4.4 Real-Time Tracking

| ID | Requirement | UR Link |
|----|-------------|---------|
| FR-TRK-001 | System shall track driver location in real-time | UR-CUS-003 |
| FR-TRK-002 | System shall display driver location on map for customer | UR-CUS-003 |
| FR-TRK-003 | System shall provide estimated time of arrival (ETA) | UR-CUS-003 |
| FR-TRK-004 | System shall update order status based on driver location | UR-DRV-006 |
| FR-TRK-005 | System shall support geofencing for pickup/delivery zones | UR-DRV-005 |

### 4.5 Communication

| ID | Requirement | UR Link |
|----|-------------|---------|
| FR-COM-001 | System shall support in-app chat between driver and customer | UR-DRV-010, UR-CUS-008 |
| FR-COM-002 | System shall send push notifications for order updates | UR-DRV-003 |
| FR-COM-003 | System shall send SMS notifications for critical events | UR-DRV-003 |
| FR-COM-004 | System shall support in-app notifications center | UR-DRV-003 |

### 4.6 Document Management

| ID | Requirement | UR Link |
|----|-------------|---------|
| FR-DOC-001 | System shall allow drivers to upload identification documents | UR-DRV-008 |
| FR-DOC-002 | System shall support document verification workflow | UR-ADM-002 |
| FR-DOC-003 | System shall store documents securely with encryption | UR-DRV-008 |
| FR-DOC-004 | System shall notify drivers of document expiry | UR-DRV-008 |

### 4.7 Offline Support

| ID | Requirement | UR Link |
|----|-------------|---------|
| FR-OFF-001 | System shall cache order data locally on driver device | UR-DRV-009 |
| FR-OFF-002 | System shall queue actions performed offline | UR-DRV-009 |
| FR-OFF-003 | System shall sync queued actions when connectivity is restored | UR-DRV-009 |
| FR-OFF-004 | System shall handle sync conflicts with last-write-wins strategy | UR-DRV-009 |

### 4.8 Reporting & Analytics

| ID | Requirement | UR Link |
|----|-------------|---------|
| FR-RPT-001 | System shall generate driver earnings reports | UR-DRV-007 |
| FR-RPT-002 | System shall generate admin dashboard with KPIs | UR-ADM-001 |
| FR-RPT-003 | System shall support export of reports (PDF, CSV) | UR-DRV-007 |
| FR-RPT-004 | System shall provide audit logs for compliance | UR-ADM-007 |

---

## 5. Scope

### 5.1 In Scope

- Driver mobile application (Android & iOS)
- Customer mobile application (Android & iOS)
- Admin web dashboard
- RESTful API backend
- Real-time order tracking and notifications
- Payment processing integration
- Document management and verification
- Offline support for driver app
- Multi-language support (Arabic, English)
- Saudi compliance (SDAIA, ZATCA)

### 5.2 Out of Scope

- Web application for customers (future phase)
- Desktop application for drivers
- AI-powered route optimization (Phase 5)
- Voice commands and hands-free operation (Phase 5)
- Government integrations beyond ZATCA (Phase 5)
- Multi-language support beyond Arabic/English (Phase 5)
- In-app chat with voice/video calls (Phase 5)
- Fraud detection system (Phase 5)

---

## 6. Use Cases

### 6.1 UC-001: Driver Login

| Element | Description |
|---------|-------------|
| **Actor** | Driver |
| **Precondition** | Driver has registered account |
| **Trigger** | Driver opens app |
| **Flow** | 1. System displays login screen 2. Driver enters credentials 3. System validates credentials 4. System issues JWT token 5. System navigates to home screen |
| **Alternative** | 3a. Invalid credentials → show error, allow retry 3b. Account locked → show lockout message 3c. Biometric → use fingerprint/Face ID |
| **Postcondition** | Driver is authenticated and session is active |

### 6.2 UC-002: Create Order

| Element | Description |
|---------|-------------|
| **Actor** | Customer |
| **Precondition** | Customer is authenticated |
| **Trigger** | Customer taps "New Order" |
| **Flow** | 1. Customer enters pickup address 2. Customer enters delivery address 3. Customer selects order type (immediate/scheduled) 4. Customer adds order details 5. Customer selects payment method 6. Customer confirms order 7. System creates order and assigns driver |
| **Alternative** | 6a. Payment fails → show error, allow retry 6b. No drivers available → show estimated wait time |
| **Postcondition** | Order is created and driver is assigned |

### 6.3 UC-003: Accept Order

| Element | Description |
|---------|-------------|
| **Actor** | Driver |
| **Precondition** | Driver is online and available |
| **Trigger** | New order notification received |
| **Flow** | 1. System displays order details 2. Driver reviews order 3. Driver taps "Accept" 4. System updates order status 5. System notifies customer 6. System provides navigation to pickup |
| **Alternative** | 3a. Driver taps "Reject" → order goes to next available driver 3b. Timeout → order automatically reassigned |
| **Postcondition** | Order is accepted and driver is en route to pickup |

### 6.4 UC-004: Complete Delivery

| Element | Description |
|---------|-------------|
| **Actor** | Driver |
| **Precondition** | Driver has picked up order |
| **Trigger** | Driver arrives at delivery location |
| **Flow** | 1. Driver confirms arrival 2. Customer provides delivery code or signature 3. Driver marks order as delivered 4. System processes payment 5. System sends receipt to customer 6. System prompts customer for rating |
| **Alternative** | 2a. Customer not available → driver waits, then escalates 3a. Delivery fails → driver marks as failed, system handles |
| **Postcondition** | Order is completed, payment is processed |

---

## 7. Acceptance Criteria

| FR ID | Acceptance Criteria |
|-------|-------------------|
| FR-AUTH-001 | User can register and login with email/password within 3 seconds |
| FR-AUTH-003 | Biometric login completes within 2 seconds |
| FR-ORD-001 | Order creation completes within 5 seconds |
| FR-ORD-002 | Order assignment to nearest driver completes within 3 seconds |
| FR-TRK-001 | Driver location updates every 5 seconds with 95% accuracy |
| FR-PAY-001 | Payment processing completes within 10 seconds |
| FR-OFF-001 | Offline queue syncs within 30 seconds of reconnection |
| FR-RPT-001 | Earnings report generates within 5 seconds |

---

*This document is the official requirements specification for the SAEQ platform. All changes require stakeholder approval.*