# Microservices
## 1. Technology and Tooling Choices
### 1.1 Containerization and Runtime

* **Docker** — containerization for all services
* **Docker Compose** — simple orchestration for MVP (single `up` command)

### 1.2 Reverse Proxy and Routing

* **Traefik**

  * HTTP routing by domain
  * TLS support (optional at MVP stage)
  * Authentication middleware support

### 1.3 Application Services

* **Python Service**

  * Language: Python 3.11+
  * Framework: FastAPI
  * Server: Uvicorn (ASGI)

* **JavaScript Service**

  * Runtime: Node.js (LTS)
  * Framework: Fastify

### 1.4 Interfaces and Service Communication

* **REST APIs**

  * HTTP/JSON
  * Versioned endpoints (e.g. `/api/v1/...`)
  * OpenAPI specification

    * FastAPI: built-in OpenAPI (`/docs`, `/openapi.json`)
    * Fastify: OpenAPI via Swagger plugin
* **API Conventions**

  * Standardized error responses
  * Correlation header: `X-Request-Id`

### 1.5 Event Bus / Message Queue

* **RabbitMQ** (AMQP)

  * Asynchronous service-to-service communication
  * Decoupling of microservices
  * Message-based integration
* **Event Model**

  * Example event: `item.created`
  * Payload: `{ id, timestamp, source_service }`
  * Headers: `correlation_id`, `idempotency_key`

### 1.6 Authentication and Security

* **authentik** (self-hosted)

  * OpenID Connect (OIDC)
  * Single Sign-On (SSO)
  * Centralized authentication
  * Forward-auth via Traefik (no auth logic inside services)

### 1.7 Logging

* **Strategy**: structured JSON logs to stdout
* **Collector**: Promtail
* **Storage**: Grafana Loki

### 1.8 Metrics

* **Prometheus** — metrics scraping and storage
* **/metrics endpoint** exposed by services

### 1.9 Tracing (optional, but planned)

* **OpenTelemetry SDK** (Python / Node.js)
* **OpenTelemetry Collector**
* **Grafana Tempo**

### 1.10 Databases

* **PostgreSQL**

  * Separate database per microservice
  * No shared database schema between services

### 1.11 Configuration

* **Environment variables** (`.env` files)
* Configuration externalized from application code

### 1.12 Idempotency

* **Idempotency-Key HTTP header** for write operations
* Prevents duplicate side effects on repeated requests
* Keys stored per service in its own database

### 1.13 CORS

* Cross-Origin Resource Sharing enabled
* Allowed origins configured via environment variables

### 1.14 Testing

* **Postman** or **Bruno**

  * REST API testing
  * Verification of idempotency behavior
  * Verification of message queue communication

### 1.15 Visualization and UI

* **Grafana**

  * Logs (Loki)
  * Metrics (Prometheus)
  * Traces (Tempo)

## Architecture
```
Client (Postman)
   |
   v
Python Service (REST)
   |
   | publish message
   v
RabbitMQ
   |
   | consume message
   v
JavaScript Service
```

