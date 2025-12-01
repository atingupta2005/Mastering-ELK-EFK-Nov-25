# Day 10 – Performance Tuning (Elasticsearch 9.x | CentOS)

> **Note for docker-elk users:**
> - Default credentials: `elastic:changeme` (update if changed in `.env`)
> - All curl commands require authentication: `curl -u elastic:changeme ...`

This document explains **basic performance tuning techniques** for Elasticsearch. It focuses on simple, practical tuning related to:

* Improving indexing speed
* Query performance tuning
* Impact of hardware
* Index lifecycle management for performance

---

## 1. Improving Indexing Speed (Bulk API, Refresh Interval)

Indexing speed means **how fast data can be written into Elasticsearch**. If indexing is slow, logs may get delayed in Kibana.

---

### 1.1 Why Indexing Can Become Slow

Common reasons for slow indexing:

* Single document inserts instead of bulk
* Very frequent refresh operations
* Limited CPU or disk speed
* Too many small indexing requests

---

### 1.2 Using Bulk API to Improve Indexing Speed

Instead of sending **one document at a time**, Elasticsearch allows you to send **many documents in one request** using the **Bulk API**.

Simple example (bulk request format):

```bash
POST _bulk
{ "index" : { "_index" : "app-logs" } }
{ "message" : "log entry 1" }
{ "index" : { "_index" : "app-logs" } }
{ "message" : "log entry 2" }
```

Why bulk is faster:

* Fewer network calls
* Better use of CPU
* Faster overall indexing

---

### 1.3 Refresh Interval and Indexing Speed

Elasticsearch refreshes indices to make new data searchable. **Frequent refresh = slower indexing**.

Default refresh interval is usually **1 second**.

You can increase it during heavy indexing:

```bash
PUT app-logs/_settings
{
  "index" : {
    "refresh_interval" : "30s"
  }
}
```

After bulk loading is complete, it can be set back to normal.

---

### ASCII Diagram – Single Insert vs Bulk Insert

```
Single Inserts:
Client → ES
Client → ES
Client → ES   (Many small requests)

Bulk Inserts:
Client → ES  (Many documents in one request)
```

---

## 2. Query Performance Tuning (Filters vs Queries, Caching)

Query performance means **how fast search results are returned**.

---

### 2.1 Filters vs Queries (Simple Difference)

* **Queries** calculate relevance score
* **Filters** only match or not match (true/false)

Filters are **faster** because no scoring is needed.

Simple example:

* Searching for `"error"` → query
* Filtering `status = 500` → filter

---

### 2.2 Why Filters Are Faster

* No scoring calculation
* Can reuse cached results
* Faster execution on large datasets

---

### 2.3 Query Caching (Basic Idea)

When the same filter is used again, Elasticsearch can **reuse the previous result** instead of recomputing it.

Simple example:

* Dashboard shows logs for `status = 200`
* Same filter is used every 10 seconds
* Elasticsearch serves cached result

This improves dashboard speed.

---

### ASCII Diagram – Query vs Filter Flow

```
Query:
Search → Score → Sort → Result

Filter:
Match → True/False → Result
```

---

## 3. Impact of Hardware (RAM, SSD, CPU)

Hardware plays a **major role** in Elasticsearch performance.

---

### 3.1 RAM (Memory)

* Used for file system cache
* Used for JVM heap
* More RAM = faster search and indexing

Simple rule:

* Half of system RAM is usually given to JVM heap
* Remaining is used by OS for caching

---

### 3.2 SSD vs HDD

* **SSD** → Very fast read/write → Best for Elasticsearch
* **HDD** → Slow → Searches and indexing become slow

Always prefer **SSD for data nodes**.

---

### 3.3 CPU

* More CPU cores help in:

  * Faster indexing
  * Faster searches
  * Faster aggregations

Low CPU can cause:

* Slow dashboards
* Delayed indexing

---

### ASCII Diagram – Hardware Impact

```
Good Hardware:
High RAM + SSD + Multi-Core CPU → Fast Indexing & Search

Weak Hardware:
Low RAM + HDD + Single CPU → Slow Indexing & Search
```

---

## 4. Index Lifecycle Management for Performance

As log data grows, old data can slow down the cluster. **Index Lifecycle Management (ILM)** helps control data automatically.

---

### 4.1 Why ILM Is Needed

Without ILM:

* Old indices remain forever
* Storage becomes full
* Searches become slower

With ILM:

* Old data can be deleted automatically
* Storage remains under control
* Cluster stays fast

---

### 4.2 Simple ILM Use Case

Example:

* Keep logs for **30 days**
* Delete logs older than **30 days**

This ensures:

* Disk space is freed automatically
* No manual cleanup required

---

### ASCII Diagram – Index Lifecycle

```
New Logs → Active Index → Old Index → Deleted
```

---

## Verification and Observation Commands

Check index refresh interval:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/app-logs/_settings?pretty"
```

Check cluster performance health:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cluster/health?pretty"
```

Check disk usage by indices:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/indices?v"
```

---
