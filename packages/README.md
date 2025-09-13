# Shared Packages

This directory contains shared, versioned Go modules and utilities that support the **atomic-commerce** system.  
Unlike the deployable applications in `/apps`, these packages are **libraries** meant to be imported across multiple services.

The core principle is **reusability and separation of concerns**, ensuring that common functionality (e.g., database access, messaging, or observability) is centralized and consistent across the system.

---

## Package Overview

### 1. `tools/`
**Description:**  
A special module for managing developer tools (e.g., `air`, linters, code generators).  
This ensures tool dependencies are versioned and reproducible.

**Core Responsibility:**  
Provide pinned versions of dev tools via `go install`, keeping them isolated from application dependencies.

---

### 2. `database/`
**Description:**  
Database utilities, schema management, and migration helpers.

**Core Responsibility:**
- Centralize database connection logic
- Manage schema migrations and rollback scripts
- Provide shared database helpers for services

---

### 3. `messaging/`
**Description:**  
A thin abstraction over the message queue (e.g., NATS, Kafka, RabbitMQ).

**Core Responsibility:**
- Standardize publishing and consuming events
- Provide typed event contracts to prevent drift
- Ensure idempotency and retry safety

---

### 4. `observability/`
**Description:**  
Shared logging, metrics, and tracing utilities.

**Core Responsibility:**
- Provide a unified logging interface
- Export metrics to Prometheus / OpenTelemetry
- Standardize trace IDs across services

---

## Development

- Each package is its own **Go module** with its own `go.mod`.
- Packages are imported by services in `/apps` using their module path.
- Versioning can be managed via `replace` directives in the root `go.work` file.

Refer to the root **Makefile** for commands related to building and linting shared packages.
