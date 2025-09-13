# Application Services

This directory contains the individual, deployable applications that constitute the **atomic-commerce** system.  
Each service is a self-contained Go module designed with a single responsibility, following professional microservices principles.

The core architectural principle is a **decoupled, asynchronous design** to ensure high availability and data integrity during high-traffic events. The user-facing API is separated from the stateful backend processing via a message queue.

---

## Service Overview

### 1. `api-gateway/`
**Description:**  
A stateless, user-facing entry point for all incoming requests.

**Tech Stack:**
- Go (Gin)

**Core Responsibility:**  
Validate requests, generate idempotency keys, and publish events to the message queue.  
This service is optimized for **low latency** and performs no slow or blocking operations.

---

### 2. `workers/`
**Description:**  
The asynchronous, stateful processing engine for all mission-critical, idempotent operations.

**Tech Stack:**
- Go

**Core Responsibility:**  
Consume events from the message queue and execute business logic within an **atomic, locked database transaction**.  
This service is optimized for **correctness, reliability, and data integrity**.

---

### 3. `admin-dashboard/`
**Description:**  
A simple, internal-facing UI for system management and monitoring.

**Tech Stack:**
- Streamlit / React

**Core Responsibility:**  
Provide an interface for creating products, setting inventory, and viewing successful orders for fulfillment.

---

## Development

All services are managed and orchestrated from the **monorepo root**.  
Refer to the root **Makefile** and **docker-compose.yml** for commands to run, test, and manage the lifecycle of these applications.
