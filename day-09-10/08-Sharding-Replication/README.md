# Day 10 – Sharding & Replication (Elasticsearch 9.x | CentOS)

> **Note for docker-elk users:**
> - Default credentials: `elastic:changeme` (update if changed in `.env`)
> - All curl commands require authentication: `curl -u elastic:changeme ...`

---

## 1. What Is a Shard?

A **shard** is a small part of an index. Elasticsearch divides every index into shards so that data can be stored across multiple nodes.

Instead of keeping all data in one place, the data is split and distributed.

Simple example:

* If an index has **1,000,000 documents**
* And it has **5 shards**
* Then each shard will store about **200,000 documents**

This makes searching faster and allows Elasticsearch to scale.

---

## 2. Primary vs Replica Shards (Detailed)

Each index in Elasticsearch has:

* **Primary shards** – original data
* **Replica shards** – copies of primary shards

---

### 2.1 Primary Shards

A **primary shard** is where the actual data is first stored.

Key points:

* Every document is first written to a **primary shard**
* The number of primary shards is fixed at index creation time
* Primary shards decide how data is distributed

Example:

```text
Index: app-logs
Primaries: 2
```

This means all data will be divided into **2 main parts**.

---

### 2.2 Replica Shards

A **replica shard** is an exact **copy of a primary shard**.

Key points:

* Used for **high availability**
* Used for **faster searches**
* Can be changed at any time

Example:

```text
Primaries: 2
Replicas: 1
Total shards = 4
```

---

### 2.3 Primary vs Replica – Simple Comparison

| Feature                    | Primary Shard | Replica Shard |
| -------------------------- | ------------- | ------------- |
| Stores original data       | Yes           | No (copy)     |
| Accepts write requests     | Yes           | No            |
| Used for search            | Yes           | Yes           |
| Used for high availability | No            | Yes           |

---

### ASCII Diagram – Primary and Replica Shards

```
Index: logs

Node 1: Primary Shard 0
Node 2: Primary Shard 1
Node 3: Replica of Shard 0
Node 4: Replica of Shard 1
```

---

### 2.4 What Happens When a Data Node Fails?

If a node holding a **primary shard fails**:

* The replica shard is **promoted to primary**
* A new replica is created on another node
* The application does **not lose data**

Simple example:

* Primary shard goes down
* Replica becomes the new primary automatically

---

## 3. How Re-Sharding Works

**Re-sharding** means changing the number of shards of an index. Since the number of primary shards cannot be directly changed after index creation, Elasticsearch uses other methods.

---

### 3.1 Why Re-Sharding Is Needed

Re-sharding is needed when:

* Data volume increases
* Search becomes slow
* More nodes are added to the cluster

---

### 3.2 Common Re-Sharding Methods

Simple approaches:

* Create a **new index** with more shards
* Reindex data from the old index to the new one

---

### 3.3 Simple Re-Sharding Example

1. Old index:

```text
app-logs-v1 → 2 primary shards
```

2. New index:

```text
app-logs-v2 → 4 primary shards
```

3. Reindex old data into new index
4. Point application to the new index

---

### ASCII Diagram – Re-Sharding

```
Old Index (2 Shards)        New Index (4 Shards)

Shard 0  ─────────────▶   Shard 0
Shard 1  ─────────────▶   Shard 1
                         Shard 2
                         Shard 3
```

---

## 4. Cluster Rebalancing Explained

**Cluster rebalancing** is the automatic movement of shards across nodes by Elasticsearch to keep the load evenly distributed.

---

### 4.1 When Rebalancing Happens

Rebalancing happens when:

* A new data node is added
* A data node leaves or fails
* An index is created or deleted
* Replica count is changed

---

### 4.2 What Happens During Rebalancing

1. Master node detects a cluster change
2. It decides how shards should be redistributed
3. Shards start moving between nodes
4. Data is copied safely
5. Once complete, the cluster becomes stable again

---

### ASCII Diagram – Cluster Rebalancing

```
Before Adding New Node:

Node 1: Shard 0, Shard 1
Node 2: Shard 2, Shard 3

After Adding New Node:

Node 1: Shard 0
Node 2: Shard 1
Node 3: Shard 2, Shard 3
```

---

### 4.3 Effect of Rebalancing on the Cluster

* Searches may become slightly slower for a short time
* Data remains available
* No data is lost
* Cluster automatically returns to normal

---

## Verification and Observation Commands

Check shard distribution:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/shards?v"
```

Check cluster health during rebalancing:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cluster/health?pretty"
```

Check index settings (shards and replicas):

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/app-logs/_settings?pretty"
```

