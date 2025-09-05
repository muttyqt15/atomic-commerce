# Merch-Drop API: A High-Concurrency E-commerce Engine

**Status:** In Development  
**Primary Tech:** Go, PostgreSQL, Docker, GCP

This repository documents the architecture and development of a **high-concurrency, fault-tolerant backend system** designed to manage limited-edition merchandise drops **without crashing, overselling, or double-charging**.

---

## 1. The Mission
To solve the *"merch drop nightmare"* faced by student organizations by building a **bulletproof, idempotent API** that can handle massive, sudden traffic spikes with **100% data integrity**.  
This project is an exercise in building **mission-critical, financial-grade systems**.

---

## 2. Core Architecture
The system is built as a **decoupled, asynchronous set of microservices** on a **serverless, cloud-native foundation (GCP)**.

The core principle:
> Separate the **fast, user-facing API** from the **slower, complex backend processing** to ensure **high availability under extreme load**.

---

## 3. Key Technical Challenges & Solutions

This project is specifically designed to tackle **three fundamental backend engineering challenges:**

### **Concurrency & Race Conditions**
- **Problem:** Overselling and data corruption during flash sales.
- **Solution:**  
  Use **atomic database transactions** with **pessimistic locking** (`SELECT ... FOR UPDATE`) in the worker service.

---

### **Idempotency**
- **Problem:** Duplicate payment requests leading to double-charging.
- **Solution:**  
  Implement a **robust idempotency key layer** to ensure every request is **processed exactly once**.

---

### **Asynchronous Processing**
- **Problem:** Traffic spikes overwhelm the backend, causing lost orders or downtime.
- **Solution:**  
  **Decouple** the API gateway from the worker service using a **GCP Pub/Sub message queue**, ensuring no orders are lost even during failures.

---

## 4. Development Roadmap (Sprints)

This system is being developed in **clear, focused sprints**, each targeting a specific milestone.

- **Sprint 1 – In Progress:**  
  *The Foundation*
    - Build a professional data layer using `golang-migrate` for versioned schemas.
    - Use `sqlc` for type-safe queries.

- **Sprint 2 – Upcoming:**  
  *The Engine*
    - Implement the **fault-tolerant, asynchronous worker service**.

- **Sprint 3 – Upcoming:**  
  *The Interface*
    - Build the **lightweight, non-blocking API gateway**.

- **Sprint 4 – Upcoming:**  
  *The Proof*
    - Execute **k6 load testing**.
    - Deploy to **GCP** with full **CI/CD pipeline** and **observability tools**.

---

## Why This Matters
This is not a toy project.  
The Merch-Drop API is a **real-world exercise in production-grade backend design**, simulating the challenges faced by **high-demand e-commerce platforms** like Shopify flash sales or sneaker drops.

> The goal is to **master core backend concepts** by solving them **from first principles**, not by relying on pre-built frameworks.

---

## Follow the Journey
This project is **actively being developed**.  
Check back to see how a **mission-critical backend system** evolves from a concept into a **fully deployed cloud solution**.
