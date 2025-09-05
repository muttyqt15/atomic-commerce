# Merch-Drop API: A High-Concurrency Headless Commerce Engine

**Status:** In Development  
**Primary Tech:** Go, PostgreSQL, Docker, GCP

This repository documents the architecture and development of a **headless commerce backend** designed to power **limited-edition pop-up stores and merch drops** — handling massive, sudden traffic spikes **without crashing, overselling, or double-charging**.

---

## 1. The Mission
Pop-up stores and merch drops create intense, short-lived traffic bursts that **break traditional e-commerce systems**.  
The mission of this project is to build a **bulletproof, idempotent API** that guarantees **100% data integrity** even under extreme load.

This project is an exercise in building **mission-critical, financial-grade systems** for organizations that need **scalability, resilience, and trust**.

---

## 2. Core Architecture
The system follows a **headless, decoupled architecture** built on a **serverless, cloud-native foundation (GCP)**.

The core principle:
> Keep the **user-facing storefront lightweight and fast**, while delegating all complex business logic and order processing to a **robust, asynchronous backend**.

---

## 3. Key Technical Challenges & Solutions

This project addresses **three core backend engineering problems** found in high-concurrency commerce systems:

### **Concurrency & Race Conditions**
- **Problem:** Overselling and inventory corruption during flash sales.
- **Solution:**  
  Use **atomic database transactions** with **pessimistic locking** (`SELECT ... FOR UPDATE`) in the worker service to ensure accurate inventory handling.

---

### **Idempotency**
- **Problem:** Duplicate checkout or payment requests leading to **double-charging** or inconsistent states.
- **Solution:**  
  Implement a **robust idempotency key layer** to guarantee each request is **processed exactly once**.

---

### **Asynchronous Processing**
- **Problem:** Synchronous APIs bottleneck under extreme traffic, leading to failures and dropped orders.
- **Solution:**  
  **Decouple** the API gateway from the processing layer using **GCP Pub/Sub**, ensuring reliability even during system spikes or partial outages.

---

## 4. Development Roadmap (Sprints)

The system is being built in **incremental, production-focused sprints**:

- **Sprint 1 – In Progress:**  
  *The Foundation*
    - Implement a professional data layer with `golang-migrate` for versioned schemas.
    - Use `sqlc` for type-safe, maintainable queries.

- **Sprint 2 – Upcoming:**  
  *The Engine*
    - Build the **fault-tolerant, asynchronous worker service**.

- **Sprint 3 – Upcoming:**  
  *The Interface*
    - Implement the **lightweight, non-blocking API gateway** for storefront integrations.

- **Sprint 4 – Upcoming:**  
  *The Proof*
    - Run **k6 load testing** under simulated flash-sale traffic.
    - Deploy to **GCP** with full **CI/CD** and **observability stack**.

---

## Why This Matters
Traditional e-commerce backends aren’t designed for **ephemeral, high-demand pop-up stores**.  
The Merch-Drop API provides a **headless, scalable core** purpose-built to handle extreme, time-limited events — similar to **Shopify flash sales** or **limited sneaker drops**, but built **from first principles**.

> The goal is to **master distributed backend systems** while solving a real, high-stakes commerce problem.

---

## Follow the Journey
This project is **actively being developed**.  
Follow along to see how a **headless, production-grade commerce system** evolves from concept to **cloud deployment**.
