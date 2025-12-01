# Day 12 – Advanced Security (Elasticsearch 9.x | CentOS)

> **Note for docker-elk users:**
> - All commands should be run from the `docker-elk` directory
> - Default credentials: `elastic:changeme` (update if changed in `.env`)
> - Use `docker compose` commands for Elasticsearch

---

## 1. TLS / HTTPS (Concept Only – No HTTPS in Lab)

TLS (Transport Layer Security) is used in real production systems to **encrypt network communication**. However, in this training environment, **only HTTP is used**, so TLS is explained **only as a concept**.

### 1.1 What TLS Does (In Simple Words)

* Encrypts data on the network
* Protects usernames, passwords, and API keys
* Prevents others from reading network traffic

---

### 1.2 Training Environment Note

In this course:

* Elasticsearch runs on **HTTP**
* Kibana runs on **HTTP**
* Fluentd / Logstash send data using **HTTP**

So:

* **No certificates are created**
* **No HTTPS configuration is done**
* TLS is explained only for **theoretical understanding**

---

### Conceptual Flow (Production vs Training)

```
Production:
Client → HTTPS → Elasticsearch

Training Lab:
Client → HTTP → Elasticsearch
```

---

## 2. API Keys for Secure Ingestion (Very Simple Hands‑On Using HTTP)

Even when HTTPS is not enabled, **API keys can still be used for authentication** in a training setup. This lab shows the **simplest possible API key usage over HTTP**.

---

### 2.1 Why API Keys Are Used

* Avoid storing usernames and passwords in scripts
* Easy to create and revoke
* Commonly used by ingestion tools

---

## 2.2 Create a Simple API Key (HTTP)

Create one API key using the `elastic` user:

```bash
curl -u elastic -X POST "http://localhost:9200/_security/api_key" \
  -H "Content-Type: application/json" \
  -d '{ "name": "simple-training-key" }'
```

From the response, note down:

* `id`
* `api_key`

---

### 2.3 Encode the API Key

```bash
echo -n '<id>:<api_key>' | base64
```

Copy the encoded value. It will be used in the next step.

---

## 2.4 Send One Test Document Using API Key (HTTP)

This is the **only hands‑on test** for API key usage in the training.

```bash
curl -u elastic:changeme -X POST "http://localhost:9200/api-demo/_doc" \
  -H "Authorization: ApiKey <BASE64_ENCODED_KEY>" \
  -H "Content-Type: application/json" \
  -d '{ "message": "log sent using api key over http" }'
```

---

## 2.5 Verify the Inserted Document

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/api-demo/_search?pretty"
```

You should see the test message in the output.

---

## What Is Intentionally NOT Covered in Training

To keep the workshop **simple and stable**, the following are **not included**:

* Certificate generation
* HTTPS configuration in Elasticsearch
* HTTPS configuration in Kibana
* Keystore and truststore
* Mutual TLS
* Advanced API key permissions

These topics belong to **production security hardening**, not classroom labs.

---

## Verification Commands

Check Elasticsearch service (from docker-elk directory):

```bash
docker compose ps elasticsearch
```

Test API key authentication over HTTP:

```bash
curl -H "Authorization: ApiKey <BASE64_ENCODED_KEY>" http://localhost:9200
# Note: This command is correct as-is (uses API key authentication)
```

---
