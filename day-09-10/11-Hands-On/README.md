# Day 10 – Hands-On Labs (Elasticsearch 9.x | CentOS)

> **Note for docker-elk users:**
> - Default credentials: `elastic:changeme` (update if changed in `.env`)
> - All curl commands require authentication: `curl -u elastic:changeme ...`

---

## Lab 1 – Create a Multi-Shard Index

### Objective

Create an index with multiple primary shards and replica shards.

---

### Step 1 – Create a New Index with Multiple Shards

```bash
curl -u elastic:changeme -X PUT "http://localhost:9200/lab-logs" -H 'Content-Type: application/json' -d'
{
  "settings": {
    "number_of_shards": 3,
    "number_of_replicas": 1
  }
}
'
```

---

### Step 2 – Verify the Index Settings

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/lab-logs/_settings?pretty"
```

Verify that:

* `number_of_shards` = 3
* `number_of_replicas` = 1

---

### Step 3 – Insert Sample Documents

```bash
curl -u elastic:changeme -X POST "http://localhost:9200/lab-logs/_doc" -H 'Content-Type: application/json' -d'{"message":"log one","status":200}'
curl -u elastic:changeme -X POST "http://localhost:9200/lab-logs/_doc" -H 'Content-Type: application/json' -d'{"message":"log two","status":500}'
curl -u elastic:changeme -X POST "http://localhost:9200/lab-logs/_doc" -H 'Content-Type: application/json' -d'{"message":"log three","status":404}'
```

---

### Step 4 – Verify Document Insertion

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/lab-logs/_search?pretty"
```

---

## Lab 2 – Monitor Cluster Rebalancing with _cat/shards

### Objective

Observe how shards are distributed across data nodes.

---

### Step 1 – Check Current Shard Placement

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/shards/lab-logs?v"
```

Observe:

* Which node holds each primary shard
* Which node holds each replica shard

---

### Step 2 – Simulate Rebalancing (Add a New Data Node)

Start another Elasticsearch node on a new port (example: 9201) with the same cluster name and data role.

> If only one node is available, rebalancing may not occur. This step is for multi-node setups.

---

### Step 3 – Recheck Shard Distribution

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/shards/lab-logs?v"
```

Verify that some shards move to the new node.

---

## Lab 3 – Run Performance Test Queries

### Objective

Test basic search performance and observe response timing.

---

### Step 1 – Run a Simple Match Query

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/lab-logs/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
    "match": {
      "message": "log"
    }
  }
}
'
```

---

### Step 2 – Run a Filter-Based Query

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/lab-logs/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
    "term": {
      "status": 500
    }
  }
}
'
```

---

### Step 3 – Compare Response Time

Observe the `took` value in the response:

* Match query → slightly higher time
* Filter query → generally lower time

---

## Lab 4 – Use Bulk API for Indexing Speed Test

### Objective

Compare single inserts with bulk inserts.

---

### Step 1 – Single Document Inserts (Slow Method)

```bash
curl -u elastic:changeme -X POST "http://localhost:9200/bulk-test/_doc" -H 'Content-Type: application/json' -d'{"message":"single log 1"}'
curl -u elastic:changeme -X POST "http://localhost:9200/bulk-test/_doc" -H 'Content-Type: application/json' -d'{"message":"single log 2"}'
curl -u elastic:changeme -X POST "http://localhost:9200/bulk-test/_doc" -H 'Content-Type: application/json' -d'{"message":"single log 3"}'
```

---

### Step 2 – Bulk Insert (Fast Method)

Create a file named `bulk.json`:

```json
{ "index" : { "_index" : "bulk-test" } }
{ "message" : "bulk log 1" }
{ "index" : { "_index" : "bulk-test" } }
{ "message" : "bulk log 2" }
{ "index" : { "_index" : "bulk-test" } }
{ "message" : "bulk log 3" }
```

Run the bulk command:

```bash
curl -u elastic:changeme -X POST "http://localhost:9200/_bulk" -H 'Content-Type: application/json' --data-binary @bulk.json
```

---

### Step 3 – Verify Bulk Insert

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/bulk-test/_search?pretty"
```

---

## Verification Commands (Quick Check)

Check cluster health:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cluster/health?pretty"
```

Check index list:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/indices?v"
```

Check shard placement:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/shards?v"
```

---
