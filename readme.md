# Microservices
## Setup
1. Run all services `docker compose --env-file .env -f infra/docker-compose.yml up -d`
2. Create admin and obtain the api key in the terminal from authentik `./infra/authentik-admin-key.sh .env`
3. Paste the api key in the `.env` file
4. Create infrastructure for authentik `./infra/authentik-infra.sh .env`

> TODO: check last step since the token seems to be invalid. update .env.sample. make the proper handling if the admin is created to obtain the token anyway

## 1. Technology and Tooling Choices
### 1.1 Containerization and Runtime

* **Docker** — containerization for all services
* **Docker Compose** — simple orchestration for MVP (single `up` command)

### 1.2 Reverse Proxy and Routing

* **Traefik**

  * HTTP routing by domain
  * TLS support (optional at MVP stage)
  * Authentication middleware support

> TODO checklist for Yari
1.HTTPS на локалке
https://py.localhost работает (self-signed или mkcert).
👉 Показать: TLS termination на edge.
2.HTTP → HTTPS redirect
http://py.localhost → автоматический редирект на HTTPS.
👉 Показать: security policy на уровне proxy.
3.TLS на Traefik, а не в сервисах
Сервисы слушают HTTP, Traefik — HTTPS.
👉 Показать: правильную edge-архитектуру.
4.Forward-auth (authentik) в Traefik
Без логина → 401 / redirect.
👉 Показать: аутентификация вынесена из сервисов.
5.Та же конфигурация = production-ready
Пояснение: в проде меняется только cert resolver (Let’s Encrypt).
👉 Показать: локалка ≠ костыль, а реплика прод-схемы.

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

