# SAEQ DRIVER — Development Roadmap

> **Version:** 1.0.0  
> **Status:** Draft (Pending Approval)  
> **Last Updated:** 2026-07-23  
> **Author:** Senior Flutter Software Engineer  

---

## Table of Contents

1. [Roadmap Overview](#1-roadmap-overview)
2. [Phase 0: Project Foundation](#2-phase-0-project-foundation)
3. [Phase 1: Authentication & Onboarding](#3-phase-1-authentication--onboarding)
4. [Phase 2: Core Driver Features](#4-phase-2-core-driver-features)
5. [Phase 3: Delivery & Earnings](#5-phase-3-delivery--earnings)
6. [Phase 4: Profile & Settings](#6-phase-4-profile--settings)
7. [Phase 5: Advanced Features](#7-phase-5-advanced-features)
8. [Cross-Cutting Concerns](#8-cross-cutting-concerns)
9. [Dependencies & Prerequisites](#9-dependencies--prerequisites)

---

## 1. Roadmap Overview

The development roadmap is organized into **5 phases**, each building upon the previous one. Each phase delivers a working, testable increment of the driver app.

| Phase | Name | Timeline | Key Deliverables |
|-------|------|----------|-----------------|
| Phase 0 | Project Foundation | Q3 2026 | Architecture, coding standards, CI/CD, core infrastructure |
| Phase 1 | Authentication & Onboarding | Q4 2026 | Login, registration, profile setup, app tour |
| Phase 2 | Core Driver Features | Q1 2027 | Orders list, order details, navigation, status management |
| Phase 3 | Delivery & Earnings | Q2 2027 | Active delivery, earnings tracking, payouts |
| Phase 4 | Profile & Settings | Q3 2027 | Profile management, preferences, notifications |
| Phase 5 | Advanced Features | Q4 2027+ | AI services, analytics, government integrations |

### 1.1 Success Criteria

Each phase must meet the following criteria before proceeding to the next:

- All planned features are implemented and tested
- Code coverage is 80%+
- No critical or high-severity issues
- Performance benchmarks are met
- Security review is completed
- Documentation is updated
- Stakeholder approval is obtained

---

## 2. Phase 0: Project Foundation

> **Status:** In Progress  
> **Timeline:** Q3 2026 (July — September 2026)

### 2.1 Objectives

- Establish the project architecture and development standards
- Set up CI/CD pipeline
- Implement core infrastructure (DI, logging, error handling, network)
- Create the app shell with basic UI and navigation

### 2.2 Deliverables

| # | Deliverable | Status | Notes |
|---|-------------|--------|-------|
| 1 | Architecture documentation | Complete | [ARCHITECTURE.md](./ARCHITECTURE.md) |
| 2 | Coding standards | Complete | [CODING_STANDARDS.md](./CODING_STANDARDS.md) |
| 3 | Technical strategies | Complete | [STRATEGIES.md](./STRATEGIES.md) |
| 4 | Development roadmap | Complete | [DEVELOPMENT_ROADMAP.md](./DEVELOPMENT_ROADMAP.md) |
| 5 | CI/CD pipeline | Pending | GitHub Actions workflows |
| 6 | Dependency injection setup | Pending | get_it + injectable |
| 7 | Logger service | Pending | logger package |
| 8 | Error handling framework | Pending | Exception/Failure hierarchy |
| 9 | Network layer (Dio) | Pending | Interceptors, API client |
| 10 | Secure storage | Pending | flutter_secure_storage |
| 11 | Local database | Pending | Drift (SQLite) |
| 12 | App shell | Complete | Welcome screen, basic navigation |
| 13 | Theme system | Complete | Colors, typography, Material 3 |
| 14 | Localization | Complete | Arabic (RTL) + English (LTR) |
| 15 | Test infrastructure | Pending | Test setup, mocking, coverage |

### 2.3 Tasks

#### 2.3.1 Infrastructure (Pending Approval)

- Set up `get_it` service locator with `injectable` code generation
- Implement `LoggerService` with structured logging
- Create exception hierarchy (`AppException` subtypes)
- Create failure hierarchy (`Failure` subtypes)
- Implement `AppErrorHandler` for centralized error handling
- Configure Dio with interceptors (auth, logging, retry, error)
- Set up `flutter_secure_storage` for sensitive data
- Initialize Drift database with migration support
- Set up `connectivity_plus` for network status detection
- Configure build flavors (development, staging, production)

#### 2.3.2 CI/CD (Pending Approval)

- Create `.github/workflows/ci.yml` (analysis, tests, build)
- Create `.github/workflows/cd.yml` (staging, production deploy)
- Set up code coverage reporting
- Configure quality gates (analysis, formatting, coverage)
- Set up secrets management (API keys, signing keys)

#### 2.3.3 Testing (Pending Approval)

- Set up test directory structure
- Configure `mocktail` for mocking
- Create base test utilities
- Set up golden test infrastructure
- Configure coverage thresholds

### 2.4 Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Dependency conflicts | Medium | Use `flutter pub outdated` regularly |
| CI/CD pipeline failures | High | Test workflows in a separate branch first |
| Code generation issues | Medium | Document generation steps, use build_runner |
| Platform-specific issues | Medium | Test on both Android and iOS early |

---

## 3. Phase 1: Authentication & Onboarding

> **Status:** Not Started  
> **Timeline:** Q4 2026 (October — December 2026)

### 3.1 Objectives

- Implement secure authentication (login, registration, password reset)
- Create onboarding flow (app tour, permissions, profile setup)
- Set up session management and token refresh
- Implement biometric authentication

### 3.2 Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | Login screen | Email/password login with validation |
| 2 | Registration screen | Driver registration with document upload |
| 3 | Password reset | Email/SMS-based password reset |
| 4 | Onboarding flow | App tour with feature highlights |
| 5 | Permissions screen | Request necessary permissions (location, notifications) |
| 6 | Profile setup | Initial profile creation (name, photo, vehicle info) |
| 7 | Biometric auth | Face ID / Touch ID / fingerprint login |
| 8 | Session management | Token storage, refresh, expiration handling |
| 9 | Auth guards | Route guards for authenticated routes |

### 3.3 Feature Breakdown

#### 3.3.1 Login Feature

```
features/auth/
├── data/
│   ├── datasources/
│   │   ├── auth_remote_data_source.dart
│   │   └── auth_local_data_source.dart
│   ├── models/
│   │   ├── login_request.dart
│   │   ├── login_response.dart
│   │   └── auth_token.dart
│   └── repositories/
│       └── auth_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── auth_token.dart
│   │   └── user.dart
│   ├── repositories/
│   │   └── auth_repository.dart
│   └── usecases/
│       ├── login_usecase.dart
│       ├── logout_usecase.dart
│       └── refresh_token_usecase.dart
├── presentation/
│   ├── pages/
│   │   ├── login_page.dart
│   │   ├── register_page.dart
│   │   └── forgot_password_page.dart
│   ├── widgets/
│   │   ├── email_input.dart
│   │   ├── password_input.dart
│   │   └── login_form.dart
│   └── viewmodels/
│       └── auth_viewmodel.dart
└── auth_feature.dart
```

#### 3.3.2 Onboarding Feature

```
features/onboarding/
├── presentation/
│   ├── pages/
│   │   ├── onboarding_page.dart
│   │   ├── permissions_page.dart
│   │   └── profile_setup_page.dart
│   ├── widgets/
│   │   ├── onboarding_dot_indicator.dart
│   │   ├── permission_item.dart
│   │   └── profile_form.dart
│   └── viewmodels/
│       └── onboarding_viewmodel.dart
└── onboarding_feature.dart
```

### 3.4 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/auth/login` | Authenticate user and get token |
| POST | `/api/v1/auth/register` | Register new driver |
| POST | `/api/v1/auth/refresh` | Refresh access token |
| POST | `/api/v1/auth/logout` | Invalidate session |
| POST | `/api/v1/auth/forgot-password` | Send password reset link |
| POST | `/api/v1/auth/reset-password` | Reset password with token |
| GET | `/api/v1/auth/me` | Get current user profile |

### 3.5 Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Document upload failures | Medium | Implement retry with progress indicator |
| Biometric auth not available | Low | Fall back to PIN/password |
| Token refresh race conditions | High | Use mutex/lock for token refresh |
| OTP delivery delays | Medium | Implement resend with cooldown |

---

## 4. Phase 2: Core Driver Features

> **Status:** Not Started  
> **Timeline:** Q1 2027 (January — March 2027)

### 4.1 Objectives

- Implement orders management (list, details, status updates)
- Create driver status management (online/offline, availability)
- Implement map integration for navigation
- Set up real-time order updates

### 4.2 Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | Orders list screen | Paginated list of orders with filtering/sorting |
| 2 | Order detail screen | Full order details with customer info and route |
| 3 | Driver status toggle | Online/offline status with availability settings |
| 4 | Map screen | Interactive map with driver location and route |
| 5 | Order status updates | Accept, reject, pickup, deliver status transitions |
| 6 | Real-time updates | WebSocket/stream for live order updates |
| 7 | Notifications | Push notifications for new orders |
| 8 | Earnings summary | Daily/weekly earnings overview |

### 4.3 Feature Breakdown

#### 4.3.1 Orders Feature

```
features/orders/
├── data/
│   ├── datasources/
│   │   ├── orders_remote_data_source.dart
│   │   └── orders_local_data_source.dart
│   ├── models/
│   │   ├── order_model.dart
│   │   ├── order_status.dart
│   │   └── order_item_model.dart
│   └── repositories/
│       └── orders_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── order.dart
│   │   ├── order_item.dart
│   │   └── order_status.dart
│   ├── repositories/
│   │   └── orders_repository.dart
│   └── usecases/
│       ├── get_orders_usecase.dart
│       ├── get_order_by_id_usecase.dart
│       ├── accept_order_usecase.dart
│       ├── reject_order_usecase.dart
│       ├── update_order_status_usecase.dart
│       └── get_earnings_usecase.dart
├── presentation/
│   ├── pages/
│   │   ├── orders_list_page.dart
│   │   ├── order_detail_page.dart
│   │   └── earnings_page.dart
│   ├── widgets/
│   │   ├── order_card.dart
│   │   ├── order_status_badge.dart
│   │   ├── earnings_chart.dart
│   │   └── earnings_summary.dart
│   └── viewmodels/
│       ├── orders_list_viewmodel.dart
│       ├── order_detail_viewmodel.dart
│       └── earnings_viewmodel.dart
└── orders_feature.dart
```

#### 4.3.2 Driver Feature

```
features/driver/
├── data/
│   ├── datasources/
│   │   ├── driver_remote_data_source.dart
│   │   └── driver_local_data_source.dart
│   ├── models/
│   │   ├── driver_model.dart
│   │   ├── driver_status.dart
│   │   └── location_model.dart
│   └── repositories/
│       └── driver_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── driver.dart
│   │   ├── driver_status.dart
│   │   └── driver_location.dart
│   ├── repositories/
│   │   └── driver_repository.dart
│   └── usecases/
│       ├── update_driver_status_usecase.dart
│       ├── update_location_usecase.dart
│       └── get_driver_profile_usecase.dart
├── presentation/
│   ├── pages/
│   │   ├── driver_status_page.dart
│   │   ├── map_page.dart
│   │   └── earnings_page.dart
│   ├── widgets/
│   │   ├── status_toggle.dart
│   │   ├── location_marker.dart
│   │   ├── route_polyline.dart
│   │   └── earnings_card.dart
│   └── viewmodels/
│       ├── driver_status_viewmodel.dart
│       ├── map_viewmodel.dart
│       └── earnings_viewmodel.dart
└── driver_feature.dart
```

### 4.4 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/orders` | Get paginated list of orders |
| GET | `/api/v1/orders/{id}` | Get order details |
| POST | `/api/v1/orders/{id}/accept` | Accept an order |
| POST | `/api/v1/orders/{id}/reject` | Reject an order |
| POST | `/api/v1/orders/{id}/status` | Update order status |
| GET | `/api/v1/driver/status` | Get driver status |
| PUT | `/api/v1/driver/status` | Update driver status |
| PUT | `/api/v1/driver/location` | Update driver location |
| GET | `/api/v1/driver/earnings` | Get earnings summary |
| GET | `/api/v1/orders/stream` | WebSocket for real-time updates |

### 4.5 Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Map performance on low-end devices | Medium | Use lightweight map tiles, lazy loading |
| Real-time update latency | High | Use WebSocket with fallback to polling |
| Location permission denials | High | Implement clear permission rationale |
| Order status race conditions | High | Use optimistic updates with rollback |

---

## 5. Phase 3: Delivery & Earnings

> **Status:** Not Started  
> **Timeline:** Q2 2027 (April — June 2027)

### 5.1 Objectives

- Implement active delivery flow (pickup, navigation, delivery)
- Create comprehensive earnings tracking and reporting
- Implement payout system
- Add delivery rating and feedback

### 5.2 Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | Active delivery screen | Full-screen delivery flow with navigation |
| 2 | Pickup confirmation | Confirm pickup with customer verification |
| 3 | Delivery confirmation | Confirm delivery with proof of delivery |
| 4 | Earnings dashboard | Detailed earnings with charts and filters |
| 5 | Payout system | Request and track payouts |
| 6 | Delivery rating | Rate deliveries and receive feedback |
| 7 | Trip history | Complete delivery history with details |
| 8 | Earnings export | Export earnings as PDF/CSV |

### 5.3 Feature Breakdown

#### 5.3.1 Delivery Feature

```
features/delivery/
├── data/
│   ├── datasources/
│   │   ├── delivery_remote_data_source.dart
│   │   └── delivery_local_data_source.dart
│   ├── models/
│   │   ├── delivery_model.dart
│   │   ├── delivery_status.dart
│   │   └── proof_of_delivery.dart
│   └── repositories/
│       └── delivery_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── delivery.dart
│   │   ├── delivery_status.dart
│   │   └── proof_of_delivery.dart
│   ├── repositories/
│   │   └── delivery_repository.dart
│   └── usecases/
│       ├── start_delivery_usecase.dart
│       ├── confirm_pickup_usecase.dart
│       ├── confirm_delivery_usecase.dart
│       ├── cancel_delivery_usecase.dart
│       └── get_delivery_history_usecase.dart
├── presentation/
│   ├── pages/
│   │   ├── active_delivery_page.dart
│   │   ├── pickup_confirmation_page.dart
│   │   ├── delivery_confirmation_page.dart
│   │   └── delivery_history_page.dart
│   ├── widgets/
│   │   ├── delivery_progress.dart
│   │   ├── customer_info_card.dart
│   │   ├── proof_of_delivery.dart
│   │   ├── delivery_map.dart
│   │   └── delivery_rating.dart
│   └── viewmodels/
│       ├── active_delivery_viewmodel.dart
│       ├── delivery_history_viewmodel.dart
│       └── delivery_rating_viewmodel.dart
└── delivery_feature.dart
```

### 5.4 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/deliveries/start` | Start a delivery |
| POST | `/api/v1/deliveries/{id}/pickup` | Confirm pickup |
| POST | `/api/v1/deliveries/{id}/deliver` | Confirm delivery |
| POST | `/api/v1/deliveries/{id}/cancel` | Cancel delivery |
| GET | `/api/v1/deliveries/history` | Get delivery history |
| POST | `/api/v1/deliveries/{id}/rate` | Rate a delivery |
| GET | `/api/v1/earnings` | Get earnings summary |
| POST | `/api/v1/payouts/request` | Request a payout |
| GET | `/api/v1/payouts/history` | Get payout history |

### 5.5 Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Proof of delivery upload failures | Medium | Allow offline capture, sync later |
| Navigation accuracy in Saudi Arabia | High | Use local map provider (e.g., HERE, Google Maps) |
| Payout processing delays | Medium | Integrate with reliable payment provider |
| Rating manipulation | Medium | Implement fraud detection |

---

## 6. Phase 4: Profile & Settings

> **Status:** Not Started  
> **Timeline:** Q3 2027 (July — September 2027)

### 6.1 Objectives

- Implement comprehensive profile management
- Create app settings and preferences
- Set up notification preferences
- Add support and help center

### 6.2 Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | Profile management | Edit personal info, vehicle details, documents |
| 2 | App settings | Theme, language, notification preferences |
| 3 | Notification center | In-app notification list and management |
| 4 | Support center | FAQ, contact support, report issue |
| 5 | Document management | Upload, verify, and manage driver documents |
| 6 | Vehicle management | Add, edit, and manage vehicle information |
| 7 | Earnings settings | Payout method, tax settings |
| 8 | Privacy & security | Password change, biometric settings |

### 6.3 Feature Breakdown

#### 6.3.1 Profile Feature

```
features/profile/
├── data/
│   ├── datasources/
│   │   ├── profile_remote_data_source.dart
│   │   └── profile_local_data_source.dart
│   ├── models/
│   │   ├── profile_model.dart
│   │   ├── vehicle_model.dart
│   │   └── document_model.dart
│   └── repositories/
│       └── profile_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── profile.dart
│   │   ├── vehicle.dart
│   │   └── document.dart
│   ├── repositories/
│   │   └── profile_repository.dart
│   └── usecases/
│       ├── get_profile_usecase.dart
│       ├── update_profile_usecase.dart
│       ├── upload_document_usecase.dart
│       ├── add_vehicle_usecase.dart
│       └── update_settings_usecase.dart
├── presentation/
│   ├── pages/
│   │   ├── profile_page.dart
│   │   ├── edit_profile_page.dart
│   │   ├── documents_page.dart
│   │   ├── vehicles_page.dart
│   │   ├── settings_page.dart
│   │   ├── notifications_page.dart
│   │   ├── support_page.dart
│   │   └── privacy_security_page.dart
│   ├── widgets/
│   │   ├── profile_header.dart
│   │   ├── profile_menu_item.dart
│   │   ├── document_item.dart
│   │   ├── vehicle_item.dart
│   │   ├── setting_toggle.dart
│   │   ├── notification_item.dart
│   │   └── faq_item.dart
│   └── viewmodels/
│       ├── profile_viewmodel.dart
│       ├── documents_viewmodel.dart
│       ├── vehicles_viewmodel.dart
│       ├── settings_viewmodel.dart
│       └── notifications_viewmodel.dart
└── profile_feature.dart
```

### 6.4 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/v1/profile` | Get driver profile |
| PUT | `/api/v1/profile` | Update driver profile |
| POST | `/api/v1/profile/documents` | Upload document |
| GET | `/api/v1/profile/documents` | Get all documents |
| POST | `/api/v1/profile/vehicles` | Add vehicle |
| GET | `/api/v1/profile/vehicles` | Get all vehicles |
| PUT | `/api/v1/profile/settings` | Update settings |
| GET | `/api/v1/profile/settings` | Get settings |
| GET | `/api/v1/notifications` | Get notification list |
| POST | `/api/v1/support/ticket` | Create support ticket |

### 6.5 Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| Document verification delays | Medium | Show verification status clearly |
| Large image upload failures | Medium | Compress and resize before upload |
| Settings sync conflicts | Low | Use last-write-wins with timestamps |
| Support ticket response time | Medium | Set SLA expectations |

---

## 7. Phase 5: Advanced Features

> **Status:** Not Started  
> **Timeline:** Q4 2027+ (October 2027 and beyond)

### 7.1 Objectives

- Integrate AI services for route optimization and demand forecasting
- Implement advanced analytics and reporting
- Add government integrations (taxation, permits)
- Implement multi-language support beyond Arabic/English
- Add advanced features (chat, voice commands, etc.)

### 7.2 Deliverables

| # | Deliverable | Description |
|---|-------------|-------------|
| 1 | AI route optimization | Smart route suggestions with traffic data |
| 2 | Demand forecasting | Predictive analytics for busy periods |
| 3 | Advanced analytics | Detailed performance and earnings reports |
| 4 | Government integrations | ZATCA tax reporting, permit management |
| 5 | Multi-language support | Additional languages (Urdu, Tagalog, etc.) |
| 6 | In-app chat | Driver-customer and driver-support chat |
| 7 | Voice commands | Hands-free operation for driving safety |
| 8 | Fraud detection | AI-powered fraud detection for orders |

### 7.3 Feature Breakdown

#### 7.3.1 AI Services Feature

```
features/ai_services/
├── data/
│   ├── datasources/
│   │   ├── ai_remote_data_source.dart
│   │   └── ai_local_data_source.dart
│   ├── models/
│   │   ├── route_optimization_model.dart
│   │   ├── demand_forecast_model.dart
│   │   └── fraud_detection_model.dart
│   └── repositories/
│       └── ai_repository_impl.dart
├── domain/
│   ├── entities/
│   │   ├── optimized_route.dart
│   │   ├── demand_forecast.dart
│   │   └── fraud_alert.dart
│   ├── repositories/
│   │   └── ai_repository.dart
│   └── usecases/
│       ├── get_optimized_route_usecase.dart
│       ├── get_demand_forecast_usecase.dart
│       └── detect_fraud_usecase.dart
├── presentation/
│   ├── pages/
│   │   ├── route_optimization_page.dart
│   │   ├── demand_forecast_page.dart
│   │   └── fraud_alerts_page.dart
│   ├── widgets/
│   │   ├── route_suggestion.dart
│   │   ├── forecast_chart.dart
│   │   └── fraud_alert_card.dart
│   └── viewmodels/
│       ├── route_optimization_viewmodel.dart
│       ├── demand_forecast_viewmodel.dart
│       └── fraud_detection_viewmodel.dart
└── ai_services_feature.dart
```

### 7.4 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/v1/ai/route-optimization` | Get optimized route |
| GET | `/api/v1/ai/demand-forecast` | Get demand forecast |
| POST | `/api/v1/ai/fraud-detection` | Detect fraud in order |
| GET | `/api/v1/analytics/performance` | Get performance analytics |
| GET | `/api/v1/analytics/earnings` | Get earnings analytics |
| POST | `/api/v1/government/zatca/report` | Submit ZATCA tax report |
| GET | `/api/v1/government/permits` | Get driver permits |

### 7.5 Risks

| Risk | Impact | Mitigation |
|------|--------|------------|
| AI model accuracy | High | Continuous training and validation |
| Government compliance changes | High | Regular compliance audits |
| Privacy concerns with AI | High | Transparent data usage policies |
| Voice recognition accuracy | Medium | Support multiple dialects |

---

## 8. Cross-Cutting Concerns

### 8.1 Testing Strategy by Phase

| Phase | Unit Tests | Widget Tests | Integration Tests | Target Coverage |
|-------|-----------|-------------|-------------------|-----------------|
| Phase 0 | 70% | 20% | 10% | 80% |
| Phase 1 | 70% | 20% | 10% | 80% |
| Phase 2 | 70% | 20% | 10% | 80% |
| Phase 3 | 70% | 20% | 10% | 80% |
| Phase 4 | 70% | 20% | 10% | 80% |
| Phase 5 | 70% | 20% | 10% | 80% |

### 8.2 Security by Phase

| Phase | Security Focus | Key Measures |
|-------|---------------|--------------|
| Phase 0 | Infrastructure | Secure storage, HTTPS, certificate pinning |
| Phase 1 | Authentication | JWT, biometric, session management |
| Phase 2 | Authorization | RBAC, route guards, input validation |
| Phase 3 | Data Protection | Encryption, PII handling, audit logging |
| Phase 4 | Privacy | GDPR/SDAIA compliance, data minimization |
| Phase 5 | Advanced | AI privacy, fraud detection, compliance |

### 8.3 Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| App startup time | < 2 seconds | Cold start |
| Screen transition | < 300ms | Navigation |
| API response time | < 500ms | 95th percentile |
| Frame rate | 60 FPS | UI rendering |
| Memory usage | < 200MB | Steady state |
| Battery impact | < 5% per hour | Active use |

### 8.4 Platform Support

| Platform | Phase 0 | Phase 1 | Phase 2 | Phase 3 | Phase 4 | Phase 5 |
|----------|---------|---------|---------|---------|---------|---------|
| Android | Yes | Yes | Yes | Yes | Yes | Yes |
| iOS | Yes | Yes | Yes | Yes | Yes | Yes |
| Web | Pending | Pending | Pending | Pending | Pending | Pending |
| Windows | Pending | Pending | Pending | Pending | Pending | Pending |
| macOS | Pending | Pending | Pending | Pending | Pending | Pending |
| Linux | Pending | Pending | Pending | Pending | Pending | Pending |

---

## 9. Dependencies & Prerequisites

### 9.1 Approved Dependencies

| Package | Version | Purpose | Status |
|---------|---------|---------|--------|
| flutter | SDK | UI framework | Approved |
| flutter_riverpod | ^3.3.2 | State management | Approved |
| go_router | ^17.3.0 | Navigation | Approved |
| dio | ^5.10.0 | HTTP client | Approved |
| shared_preferences | ^2.5.5 | Key-value storage | Approved |
| google_fonts | ^8.2.0 | Typography | Approved |
| flutter_screenutil | ^5.9.3 | Responsive design | Approved |
| intl | ^0.20.2 | Internationalization | Approved |
| flutter_lints | ^6.0.0 | Linting | Approved |

### 9.2 Pending Dependencies (Awaiting Approval)

| Package | Purpose | Phase | Justification |
|---------|---------|-------|---------------|
| get_it | Service locator | Phase 0 | Industry standard for DI in Flutter |
| injectable | Code generation for DI | Phase 0 | Reduces boilerplate, compile-safe |
| logger | Structured logging | Phase 0 | Better than print(), supports log levels |
| flutter_secure_storage | Secure credential storage | Phase 0 | Required for token storage |
| connectivity_plus | Network connectivity | Phase 0 | Required for offline strategy |
| json_annotation | JSON serialization | Phase 1 | Required for API models |
| retrofit | Type-safe API clients | Phase 1 | Reduces boilerplate, compile-safe |
| drift | SQLite ORM | Phase 0 | Required for local database |
| freezed | Immutable data classes | Phase 1 | Union types, copyWith, equality |
| mocktail | Mocking for tests | Phase 0 | Required for unit testing |
| firebase_core | Firebase initialization | Phase 1 | Required for FCM, Crashlytics |
| firebase_messaging | Push notifications | Phase 2 | Required for order notifications |
| firebase_crashlytics | Crash reporting | Phase 0 | Required for error monitoring |
| firebase_analytics | Analytics | Phase 2 | Required for user analytics |
| google_maps_flutter | Map integration | Phase 2 | Required for navigation |
| image_picker | Image capture/upload | Phase 1 | Required for document upload |
| file_picker | File selection | Phase 1 | Required for document upload |
| path_provider | File system access | Phase 1 | Required for file operations |
| share_plus | Share content | Phase 4 | Required for earnings export |
| flutter_svg | SVG rendering | Phase 1 | Required for scalable icons |
| cached_network_image | Image caching | Phase 1 | Required for efficient image loading |
| flutter_local_notifications | Local notifications | Phase 2 | Required for notification display |
| timezone | Timezone handling | Phase 3 | Required for accurate timestamps |
| qr_code_scanner | QR code scanning | Phase 3 | Required for proof of delivery |
| just_audio | Audio playback | Phase 5 | Required for voice commands |
| speech_to_text | Voice recognition | Phase 5 | Required for voice commands |

### 9.3 External Service Dependencies

| Service | Purpose | Phase | Notes |
|---------|---------|-------|-------|
| Firebase | Backend services (FCM, Crashlytics, Analytics) | Phase 0 | Google Cloud project required |
| ZATCA API | Tax reporting | Phase 5 | Saudi government integration |
| Payment Gateway | Payout processing | Phase 3 | To be determined (STC Pay, Mada, etc.) |
| Map Provider | Navigation and routing | Phase 2 | Google Maps or HERE Technologies |
| SMS Provider | OTP and notifications | Phase 1 | Twilio or local provider |
| Email Service | Email notifications | Phase 1 | SendGrid or similar |
| CDN | Asset delivery | Phase 2 | For images and static assets |
| Logging Service | Remote log aggregation | Phase 0 | Sentry or similar |

### 9.4 Infrastructure Requirements

| Component | Requirement | Phase |
|-----------|-------------|-------|
| CI/CD | GitHub Actions | Phase 0 |
| Code Coverage | 80% minimum | Phase 0 |
| Static Analysis | 0 errors, 0 warnings | Phase 0 |
| App Distribution | Firebase App Distribution | Phase 1 |
| Crash Reporting | Firebase Crashlytics | Phase 0 |
| Performance Monitoring | Firebase Performance | Phase 2 |
| Analytics | Firebase Analytics | Phase 2 |
| Code Obfuscation | ProGuard/R8 (Android), LLVM (iOS) | Phase 4 |
| Security Scanning | OWASP Dependency Check | Phase 0 |

---

## Appendix A: Milestone Timeline

```
2026
Q3  Phase 0: Foundation
Q4  Phase 1: Auth & Onboarding

2027
Q1  Phase 2: Core Driver Features
Q2  Phase 3: Delivery & Earnings
Q3  Phase 4: Profile & Settings
Q4  Phase 5: Advanced Features
```

### A.1 Key Milestones

| Date | Milestone | Phase |
|------|-----------|-------|
| 2026-07-23 | Architecture documentation complete | Phase 0 |
| 2026-08-15 | CI/CD pipeline operational | Phase 0 |
| 2026-09-30 | Core infrastructure complete | Phase 0 |
| 2026-10-15 | Authentication flow complete | Phase 1 |
| 2026-12-31 | Onboarding flow complete | Phase 1 |
| 2027-01-15 | Orders list and details complete | Phase 2 |
| 2027-03-31 | Map integration and navigation complete | Phase 2 |
| 2027-04-30 | Active delivery flow complete | Phase 3 |
| 2027-06-30 | Earnings and payouts complete | Phase 3 |
| 2027-07-31 | Profile management complete | Phase 4 |
| 2027-09-30 | Settings and support complete | Phase 4 |
| 2027-10-31 | AI route optimization complete | Phase 5 |
| 2027-12-31 | Advanced analytics complete | Phase 5 |

---

## Appendix B: Resource Allocation

### B.1 Team Structure

| Role | Phase 0 | Phase 1 | Phase 2 | Phase 3 | Phase 4 | Phase 5 |
|------|---------|---------|---------|---------|---------|---------|
| Lead Flutter Engineer | 100% | 100% | 100% | 100% | 100% | 100% |
| Flutter Engineer | 50% | 100% | 100% | 100% | 100% | 100% |
| Backend Engineer | 20% | 50% | 50% | 50% | 30% | 50% |
| QA Engineer | 20% | 50% | 50% | 50% | 50% | 50% |
| DevOps Engineer | 50% | 30% | 20% | 20% | 20% | 20% |
| UX/UI Designer | 30% | 50% | 50% | 30% | 50% | 30% |
| Security Engineer | 30% | 20% | 20% | 20% | 20% | 30% |
| Product Manager | 50% | 100% | 100% | 100% | 100% | 100% |

### B.2 Budget Estimation

| Category | Phase 0 | Phase 1 | Phase 2 | Phase 3 | Phase 4 | Phase 5 | Total |
|----------|---------|---------|---------|---------|---------|---------|-------|
| Development | $50K | $120K | $150K | $100K | $80K | $200K | $700K |
| Infrastructure | $10K | $15K | $20K | $15K | $10K | $25K | $95K |
| Testing | $10K | $20K | $25K | $20K | $15K | $30K | $120K |
| Security | $5K | $10K | $10K | $10K | $10K | $15K | $60K |
| **Total** | **$75K** | **$165K** | **$205K** | **$145K** | **$115K** | **$270K** | **$975K** |

---

*This document is a living document and will be updated as the architecture evolves. All changes require approval.*
