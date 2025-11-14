## 📅 Day 6: Hands-On Exercises (Capstone Lab)

### 1\. Create Template for Logs Index (Topic 27)

**Task:** Create a new, *simple* index template named `app-logs-template` that will match any new index starting with `app-logs-*`. This template will be for application-level logs.

**Action:**

```http
PUT /_index_template/app-logs-template
{
  "index_patterns": [ "app-logs-*" ],
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0
    },
    "mappings": {
      "dynamic": false,
      "properties": {
        "@timestamp": { "type": "date" },
        "service": { "type": "keyword" },
        "level": { "type": "keyword" },
        "message": { "type": "text" },
        "duration_ms": { "type": "long" },
        "trace_id": { "type": "keyword" }
      }
    }
  }
}
```

*Result: `"acknowledged": true`. The "blueprint" for your application logs is now saved.*

### 2\. Insert Sample Documents (Topic 28)

**Task:** Create a new index `app-logs-main-001` (which will match our template) and insert three sample documents. We will use `PUT` with specific IDs so we can reference them later.

**Action (Document 1):**

```http
PUT /app-logs-main-001/_doc/log-001
{
  "@timestamp": "2025-11-14T10:30:00Z",
  "service": "auth-service",
  "level": "info",
  "message": "User 'alice' login successful",
  "duration_ms": 55,
  "trace_id": "abc-111"
}
```

**Action (Document 2):**

```http
PUT /app-logs-main-001/_doc/log-002
{
  "@timestamp": "2025-11-14T10:31:00Z",
  "service": "payment-service",
  "level": "error",
  "message": "Payment processing failed: NullPointerException on line 42",
  "duration_ms": 1250,
  "trace_id": "xyz-999"
}
```

**Action (Document 3):**

```http
PUT /app-logs-main-001/_doc/log-003
{
  "@timestamp": "2025-11-14T10:32:00Z",
  "service": "auth-service",
  "level": "warn",
  "message": "Password validation failed for user 'bob' (IP: 192.168.1.10)",
  "duration_ms": 160,
  "trace_id": "abc-222"
}
```

*Result: You have successfully indexed three documents into `app-logs-main-001`.*

### 3\. Run `match` Query on Error Messages (Topic 29)

**Task:** Search the `message` (text) field for any log that contains the word "failed".

**Action:**

```http
POST /app-logs-main-001/_search
{
  "query": {
    "match": {
      "message": "failed"
    }
  }
}
```

*Result: The search will return documents `log-002` and `log-003`, as both contain the word "failed" (or "Failed") in their `message` field.*

### 4\. Run `range` Query on Response Times (Topic 30)

**Task:** Find all logs that were "slow" (e.g., took longer than 1 second, or 1000ms).

**Action:**

```http
POST /app-logs-main-001/_search
{
  "query": {
    "range": {
      "duration_ms": {
        "gt": 1000
      }
    }
  }
}
```

*Result: The search will return only document `log-002`, which had a `duration_ms` of 1250.*

### 5\. Update a Document Using `PUT` (Topic 31)

**Task:** Demonstrate the "overwrite" behavior of `PUT` by replacing document `log-001`.

**Action:**

```http
PUT /app-logs-main-001/_doc/log-001
{
  "@timestamp": "2025-11-14T10:30:00Z",
  "message": "This document has been completely overwritten."
}
```

**Action (Verification):**

```http
GET /app-logs-main-001/_doc/log-001
```

*Result: The `_source` will *only* contain the `message` and `@timestamp` fields. The original `service`, `level`, `duration_ms`, and `trace_id` fields are **gone**. This proves that `PUT` is a destructive overwrite operation.*

### 6\. Delete a Document Using ID (Topic 32)

**Task:** Delete document `log-003` from the index.

**Action:**

```http
DELETE /app-logs-main-001/_doc/log-003
```

*Result: The response will show `result: "deleted"`.*

**Action (Verification):**

```http
GET /app-logs-main-001/_doc/log-003
```

*Result: The response will show `"found": false`.*

### 7\. Search with `boolean` Query (Topic 33)

**Task:** Find all logs that are from the `auth-service` AND have a `level` of `info`.

**Action:**

```http
POST /app-logs-main-001/_search
{
  "query": {
    "bool": {
      "filter": [
        { "term": { "service": "auth-service" } },
        { "term": { "level": "info" } }
      ]
    }
  }
}
```

*Result: The search will return only document `log-001` (assuming you `PUT` the original document back after the update lab).*

### 8\. Run Aggregations (Topic 34)

**Task:** The `app-logs` index is too small for meaningful aggregations. We will switch to our large `access-logs*` index to find error counts and top IP addresses.

**Action 1: Get Error Counts (using a `filters` aggregation)**
This aggregation creates separate "buckets" for different filters.

```http
POST /access-logs*/_search
{
  "size": 0,
  "aggs": {
    "error_counts": {
      "filters": {
        "filters": {
          "404_not_found": {
            "term": { "http.response.status_code": 404 }
          },
          "500_server_error": {
            "term": { "http.response.status_code": 500 }
          },
          "503_service_unavailable": {
            "term": { "http.response.status_code": 503 }
          }
        }
      }
    }
  }
}
```

*Result: You will get a count for each error type (e.g., `404_not_found: { "doc_count": 3 }`, `500_server_error: { "doc_count": 2 }`).*

**Action 2: Get Top IP Addresses (using a `terms` aggregation)**

```http
POST /access-logs*/_search
{
  "size": 0,
  "aggs": {
    "top_ips": {
      "terms": {
        "field": "client.ip",
        "size": 10
      }
    }
  }
}
```

*Result: You will get a list of the Top 10 IP addresses in the `buckets` array, each with its `doc_count`.*