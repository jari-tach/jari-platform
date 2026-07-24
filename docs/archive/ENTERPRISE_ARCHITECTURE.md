# SAEQ DRIVER — Enterprise Architecture Documentation

> **Version:** 1.0.0
> **Status:** Draft (Pending Approval)
> **Last Updated:** 2026-07-23
> **Author:** Senior Flutter Software Engineer
> **Related Documents:** [ARCHITECTURE.md](./ARCHITECTURE.md), [STRATEGIES.md](./STRATEGIES.md), [DEVELOPMENT_ROADMAP.md](./DEVELOPMENT_ROADMAP.md), [CODING_STANDARDS.md](./CODING_STANDARDS.md)

---

## Table of Contents

1. [Multi Vendor Architecture](#1-multi-vendor-architecture)
2. [Driver App Architecture](#2-driver-app-architecture)
3. [Customer App Architecture](#3-customer-app-architecture)
4. [Merchant Dashboard](#4-merchant-dashboard)
5. [Admin Dashboard](#5-admin-dashboard)
6. [Delivery Pricing Engine](#6-delivery-pricing-engine)
7. [Smart Order Assignment Engine](#7-smart-order-assignment-engine)
8. [AI Services Layer](#8-ai-services-layer)
9. [Notification Service Architecture](#9-notification-service-architecture)
10. [Realtime Tracking Architecture](#10-realtime-tracking-architecture)
11. [Background Jobs Architecture](#11-background-jobs-architecture)
12. [Payment Gateway Layer](#12-payment-gateway-layer)
13. [Saudi Compliance Layer](#13-saudi-compliance-layer)
14. [Barcode Master Database](#14-barcode-master-database)
15. [Product Catalog Service](#15-product-catalog-service)
16. [Digital Wallet Architecture](#16-digital-wallet-architecture)
17. [Coupon & Promotion Engine](#17-coupon--promotion-engine)
18. [Loyalty System](#18-loyalty-system)
19. [Analytics & BI Layer](#19-analytics--bi-layer)
20. [Future Microservices Migration Plan](#20-future-microservices-migration-plan)
21. [Cloud Scalability Plan](#21-cloud-scalability-plan)
22. [Disaster Recovery Plan](#22-disaster-recovery-plan)
23. [Monitoring & Observability](#23-monitoring--observability)
24. [API Versioning Strategy](#24-api-versioning-strategy)
25. [Feature Flags Strategy](#25-feature-flags-strategy)
26. [Modular Feature Isolation](#26-modular-feature-isolation)
27. [Plugin System Architecture](#27-plugin-system-architecture)
28. [Offline Sync Conflict Resolution](#28-offline-sync-conflict-resolution)
29. [Enterprise Security Standards](#29-enterprise-security-standards)
30. [Performance Targets](#30-performance-targets)

---

## 1. Multi Vendor Architecture

### 1.1 Overview

The Saeq ecosystem is a **multi-vendor delivery platform** that serves multiple stakeholder types through dedicated applications, all sharing a common backend infrastructure. The platform supports four primary vendor types:

| Vendor Type | Application | Primary Users | Core Domain |
|-------------|-------------|---------------|-------------|
| **Driver** | Driver App (this project) | Delivery drivers | Order fulfillment, navigation, earnings |
| **Customer** | Customer App | End consumers | Ordering, tracking, payments |
| **Merchant** | Merchant Dashboard | Restaurants/stores | Menu management, order processing |
| **Admin** | Admin Dashboard | Platform operators | Oversight, configuration, analytics |

### 1.2 Shared Infrastructure

All vendor applications share the following common infrastructure layers:

```
┌─────────────────────────────────────────────────────────────────┐
│                    API GATEWAY & LOAD BALANCER                  │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │  Rate       │  │  Auth       │  │  Routing    │              │
│  │  Limiting   │  │  Service    │  │  Service    │              │
│  └─────────────┘  └─────────────┘  └─────────────┘              │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    MICROSERVICES LAYER                          │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────┐ │
│  │  Order      │  │  Driver     │  │  Payment    │  │  AI     │ │
│  │  Service    │  │  Service    │  │  Service    │  │  Service│ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────┘ │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────┐ │
│  │  Catalog    │  │  Notification│  │  Tracking   │  │  Admin  │ │
│  │  Service    │  │  Service     │  │  Service    │  │  Service│ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────┘ │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DATA & STORAGE LAYER                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────┐ │
│  │  Primary    │  │  Cache      │  │  Search     │  │  Object │ │
│  │  DB (PG)    │  │  (Redis)    │  │  (Elastic)  │  │ Storage │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────┘ │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    EXTERNAL INTEGRATIONS                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────┐ │
│  │  ZATCA      │  │  Nafath     │  │  Absher     │  │  Maps   │ │
│  │  API        │  │  API        │  │  API        │  │  API    │ │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### 1.3 Cross-Vendor Communication Patterns

- **Synchronous:** REST/gRPC for real-time operations (order creation, status updates)
- **Asynchronous:** Message queues (Kafka/RabbitMQ) for decoupled operations (notifications, analytics, fraud detection)
- **Event Streaming:** WebSocket/Server-Sent Events for real-time updates (tracking, order status)
- **Data Synchronization:** CDC (Change Data Capture) for cross-service data consistency

### 1.4 Tenant Isolation

- **Data Isolation:** Each vendor type has dedicated schemas/tables in the shared database
- **API Isolation:** Separate API keys and rate limits per vendor type
- **Security Isolation:** Role-based access control (RBAC) with vendor-specific permissions
- **Configuration Isolation:** Environment-specific configurations per vendor type

---

## 2. Driver App Architecture

### 2.1 Overview

The Driver App is the mobile application for delivery drivers, built with Flutter. It follows the Clean Architecture pattern with Feature-First organization as described in [ARCHITECTURE.md](./ARCHITECTURE.md).

### 2.2 Feature Modules

| Feature | Description | Phase |
|---------|-------------|-------|
| **Auth** | Login, registration, biometric auth, session management | Phase 1 |
| **Onboarding** | App tour, permissions, profile setup, document upload | Phase 1 |
| **Orders** | Order list, order details, status management | Phase 2 |
| **Driver** | Status toggle, location tracking, availability | Phase 2 |
| **Delivery** | Active delivery flow, pickup/delivery confirmation, proof of delivery | Phase 3 |
| **Profile** | Profile management, vehicle info, documents, settings | Phase 4 |
| **AI Services** | Route optimization, demand forecasting | Phase 5 |

### 2.3 Architecture Layers

```
┌─────────────────────────────────────────────────────────────────┐
│                    PRESENTATION LAYER                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐              │
│  │  Orders     │  │  Driver     │  │  Delivery   │              │
│  │  Pages      │  │  Pages      │  │  Pages      │              │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘              │
│         │                │                │                     │
│         ▼                ▼                ▼                     │
│  ┌──────────────────────────────────────────────────┐           │
│  │              STATE MANAGEMENT (Riverpod)         │           │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐            │           │
│  │  │ViewModel│  │ViewModel│  │ViewModel│            │           │
│  │  └─────────┘  └─────────┘  └─────────┘            │           │
│  └──────────────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DOMAIN LAYER                                 │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐            │
│  │Entities │  │UseCases │  │Repos    │  │AI Models│            │
│  │         │  │         │  │(Abstract)│  │         │            │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘            │
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    DATA LAYER                                   │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐            │
│  │API      │  │Local DB │  │Cache    │  │Offline  │            │
│  │(Dio)    │  │(Drift)  │  │(Redis)  │  │Queue    │            │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘            │
└─────────────────────────────────────────────────────────────────┘
```

### 2.4 Driver-Specific Considerations

- **Location Tracking:** Background location updates with battery optimization
- **Offline Support:** Full offline mode for order management and status updates
- **Battery Optimization:** Minimal background processing, adaptive refresh rates
- **Network Resilience:** Retry logic, offline queue, sync on connectivity restore
- **Saudi Localization:** Full Arabic RTL support, Saudi-specific date/time formats

---

## 3. Customer App Architecture

### 3.1 Overview

The Customer App is the mobile application for end consumers to browse menus, place orders, track deliveries, and manage payments.

### 3.2 Feature Modules

| Feature | Description | Phase |
|---------|-------------|-------|
| **Auth** | Login, registration, social login, guest checkout | Phase 1 |
| **Onboarding** | App tour, location permissions, preferences | Phase 1 |
| **Catalog** | Browse restaurants, menus, product search, filters | Phase 2 |
| **Cart** | Cart management, special instructions, tips | Phase 2 |
| **Checkout** | Address selection, payment method, order confirmation | Phase 2 |
| **Orders** | Order history, order tracking, reorder | Phase 2 |
| **Tracking** | Real-time delivery tracking with map | Phase 2 |
| **Profile** | Profile management, saved addresses, payment methods | Phase 3 |
| **Favorites** | Saved restaurants, favorite items | Phase 3 |
| **Support** | Chat support, FAQs, issue reporting | Phase 3 |

### 3.3 Architecture Differences from Driver App

| Aspect | Driver App | Customer App |
|--------|-----------|--------------|
| **Primary Focus** | Order fulfillment | Order placement |
| **Real-time Needs** | Location, order status | Order tracking |
| **Offline Needs** | High (can work offline) | Low (needs connectivity) |
| **Background Processing** | Extensive (location tracking) | Minimal (notifications) |
| **Data Volume** | Moderate | High (catalog browsing) |
| **Payment Flow** | Earnings/payouts | Checkout/payments |

---

## 4. Merchant Dashboard

### 4.1 Overview

The Merchant Dashboard is a web-based application for restaurants and stores to manage their menus, process orders, view analytics, and configure settings.

### 4.2 Feature Modules

| Feature | Description | Phase |
|---------|-------------|-------|
| **Auth** | Login, role-based access, password reset | Phase 1 |
| **Dashboard** | Overview metrics, pending orders, performance | Phase 1 |
| **Menu Management** | Product catalog, categories, pricing, availability | Phase 1 |
| **Order Management** | View, accept/reject, status updates, order details | Phase 1 |
| **Inventory** | Stock management, low stock alerts, supplier info | Phase 2 |
| **Analytics** | Sales reports, popular items, peak hours | Phase 2 |
| **Customers** | Customer insights, repeat customers, feedback | Phase 2 |
| **Settings** | Business hours, delivery zones, payment methods | Phase 2 |
| **Staff Management** | Employee roles, permissions, performance | Phase 3 |
| **Promotions** | Discounts, coupons, special offers | Phase 3 |

### 4.3 Technical Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | React.js + TypeScript + Material-UI |
| **State Management** | Redux Toolkit |
| **Routing** | React Router v6 |
| **HTTP Client** | Axios |
| **Build Tool** | Vite |
| **Testing** | Jest + React Testing Library |
| **Deployment** | Docker + Kubernetes |

### 4.4 Real-time Features

- **Order Notifications:** WebSocket for instant order alerts
- **Order Status Updates:** Real-time status changes pushed to dashboard
- **Inventory Alerts:** Real-time low stock notifications
- **Performance Metrics:** Live updating dashboards

---

## 5. Admin Dashboard

### 5.1 Overview

The Admin Dashboard is a web-based application for platform operators to oversee the entire Saeq ecosystem, manage vendors, configure system settings, and view comprehensive analytics.

### 5.2 Feature Modules

| Feature | Description | Phase |
|---------|-------------|-------|
| **Auth** | Login, RBAC, password reset, MFA | Phase 1 |
| **Overview** | Platform-wide metrics, KPIs, alerts | Phase 1 |
| **Vendor Management** | Register, approve, suspend merchants/drivers | Phase 1 |
| **Order Oversight** | Search, filter, investigate orders, dispute resolution | Phase 1 |
| **User Management** | Customer accounts, support tickets, complaints | Phase 2 |
| **Financials** | Revenue reports, payouts, commissions, refunds | Phase 2 |
| **Content Management** | Static pages, FAQs, terms, privacy policy | Phase 2 |
| **System Configuration** | API settings, feature flags, rate limits | Phase 2 |
| **Compliance** | ZATCA reporting, audit logs, regulatory reports | Phase 3 |
| **Analytics** | Business intelligence, forecasting, insights | Phase 3 |
| **Support Center** | Ticket management, knowledge base, chat | Phase 3 |

### 5.3 RBAC Roles

| Role | Permissions |
|------|------------|
| **Super Admin** | Full access to all features and settings |
| **Platform Manager** | Vendor management, financials, compliance |
| **Operations Manager** | Order oversight, user management, support |
| **Content Manager** | Content management, FAQs, static pages |
| **Support Agent** | Support tickets, user inquiries, dispute resolution |
| **Analyst** | Analytics, reports, business intelligence (read-only) |