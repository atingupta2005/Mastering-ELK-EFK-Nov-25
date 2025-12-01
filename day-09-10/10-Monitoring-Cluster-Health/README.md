# Day 10 – Monitoring Cluster Health (Elasticsearch 9.x | CentOS)

> **Note for docker-elk users:**
> - Default credentials: `elastic:changeme` (update if changed in `.env`)
> - All curl commands require authentication: `curl -u elastic:changeme ...`

This document explains how to **monitor the health and performance of an Elasticsearch cluster** using:

* _cat APIs to monitor nodes and indices
* Kibana Monitoring UI
* Basic approach to identifying bottlenecks in query latency

All explanations are kept **simple**, **practical**, and include **examples and ASCII diagrams**.

---

## 1. Using _cat APIs to Monitor Nodes and Indices

Elasticsearch provides **_cat APIs** for quick, human‑readable monitoring of the cluster. These APIs are commonly used from the terminal to check the real‑time status of nodes, indices, and shards.

---

### 1.1 Checking Overall Cluster Health

This command shows whether the cluster is in **green, yellow, or red** state.

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cluster/health?pretty"
```

Output fields (simple meaning):

* `status` → overall health (green / yellow / red)
* `number_of_nodes` → total nodes in the cluster
* `active_shards` → shards currently working

Meaning of cluster states:

* **Green** → All primary and replica shards are working
* **Yellow** → All primary shards are working, some replicas missing
* **Red** → Some primary shards are not working (data at risk)

---

### 1.2 Monitoring Nodes with _cat/nodes

This command lists all nodes and their basic resource usage.

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/nodes?v"
```

You can observe:

* Node name
* IP address
* Roles (master, data, ingest, etc.)
* CPU usage
* Heap usage

Simple use:

* Identify which node is under high CPU or memory load

---

### 1.3 Monitoring Indices with _cat/indices

This command shows all indices and their storage details.

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/indices?v"
```

Key columns to observe:

* `index` → index name
* `health` → health of individual index
* `docs.count` → number of documents
* `store.size` → disk space used

This helps in:

* Finding large indices
* Finding unhealthy indices

---

### 1.4 Monitoring Shards with _cat/shards

This command shows where each shard is placed.

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/shards?v"
```

You can observe:

* Primary (p) and replica (r) shards
* Node on which each shard is stored
* State of each shard

This is useful for:

* Understanding data distribution
* Checking rebalancing activity

---

### ASCII Diagram – Using _cat APIs for Monitoring

```
Admin Terminal
      |
      v
+-------------------------+
|  _cluster/health        |
|  _cat/nodes             |
|  _cat/indices           |
|  _cat/shards            |
+-------------------------+
              |
              v
         Elasticsearch Cluster
```

---

## 2. Monitoring with Kibana Monitoring UI

Kibana provides a **visual dashboard** for monitoring the Elasticsearch cluster. It is useful for students and administrators who prefer a graphical view instead of terminal commands.

---

### 2.1 What Can Be Seen in Kibana Monitoring

From the Kibana Monitoring section, you can see:

* Overall cluster health
* Node CPU and memory usage
* Indexing rate
* Search rate
* JVM heap usage

---

### 2.2 Accessing Monitoring in Kibana

Basic steps:

1. Open Kibana in the browser
2. Go to **Stack Monitoring**
3. Select **Elasticsearch**
4. View cluster, node, and index metrics

---

### 2.3 Why Kibana Monitoring Is Useful

* Real‑time graphs
* Easy to spot spikes in load
* Helpful for beginners to understand cluster behavior

---

### ASCII Diagram – Kibana Monitoring View

```
Browser → Kibana → Monitoring Dashboard → Elasticsearch Metrics
```

---

## 3. Identifying Bottlenecks in Query Latency

A **bottleneck** means something is slowing down search queries or indexing.

---

### 3.1 Common Signs of Bottlenecks

* Searches take a long time
* Dashboards load slowly
* CPU usage stays very high
* Heap memory stays near maximum

---

### 3.2 Simple Checks to Identify Bottlenecks

Using commands:

1. Check cluster health:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cluster/health?pretty"
```

2. Check node load:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/nodes?v"
```

3. Check index sizes:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/indices?v"
```

From these, you can easily detect:

* Overloaded nodes
* Very large indices
* Unhealthy shard allocation

---

### 3.3 Simple Bottleneck Example

Example situation:

* One data node shows very high CPU
* Other nodes are mostly idle

This indicates:

* Data is not evenly distributed
* Rebalancing may be required

---

### ASCII Diagram – Bottleneck Example

```
Node 1: High CPU  ██████████
Node 2: Low CPU   ██
Node 3: Low CPU   ██

→ Node 1 is a performance bottleneck
```

---

## Verification and Observation Commands

Check cluster health:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cluster/health?pretty"
```

Check nodes and resource usage:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/nodes?v"
```

Check indices and disk usage:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/indices?v"
```

Check shard distribution:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/shards?v"
```

---

## Summary

* _cat APIs provide quick, readable cluster status
* _cluster/health shows overall cluster state
* _cat/nodes shows node‑level resource usage
* _cat/indices shows index size and health
* _cat/shards shows shard placement
* Kibana Monitoring UI gives visual monitoring
* Bottlenecks can be identified using simple health and node checks

Monitoring cluster health regularly helps keep Elasticsearch stable and responsive.
