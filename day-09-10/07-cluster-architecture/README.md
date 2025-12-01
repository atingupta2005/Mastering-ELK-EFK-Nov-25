# Day 10 – Cluster Architecture (Elasticsearch 9.x | CentOS)

> **Note for docker-elk users:**
> - Default credentials: `elastic:changeme` (update if changed in `.env`)
> - All curl commands require authentication: `curl -u elastic:changeme ...`

This document explains the **Cluster Architecture of Elasticsearch** in a clear and practical manner for students. It introduces different node types, shows how data is distributed across the cluster, and explains the role of cluster state using simple examples and diagrams.

---

## 1. Node Types – Master, Data, Coordinating, Ingest

An **Elasticsearch node** is a running instance of Elasticsearch. A **cluster** is a group of such nodes working together.

Each node is assigned one or more **roles**. A role decides what work the node will perform.

The main node types used in this course are:

* Master node
* Data node
* Coordinating node
* Ingest node

---

### 1.1 Master Node

The **master node** controls and manages the **entire cluster**. It does **not store log data** and does **not handle searches**.

Main responsibilities of a master node:

* Keeps track of all nodes in the cluster
* Creates and deletes indices
* Decides where shards should be placed
* Monitors whether nodes join or leave the cluster

Simple example:

* If a new data node is added, the master node decides which shards should move to that new node.

Basic configuration example:

```yaml
node.roles: [ master ]
```

Check the current master node:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/master?v"
```

### ASCII Diagram – Master Node Control

```
                +-----------------+
                |   Master Node   |
                |-----------------|
                | Cluster Control |
                | Shard Decisions |
                +-----------------+
                          |
        -----------------------------------------------
        |                     |                     |
   +-----------+        +-----------+        +-----------+
   | Data Node |        | Data Node |        | Data Node |
   +-----------+        +-----------+        +-----------+
```

---

### 1.2 Data Node

A **data node** stores the **actual documents** and performs **search and indexing operations**.

Main responsibilities:

* Stores log and application data
* Holds primary and replica shards
* Executes searches and returns results

Simple example:

* When you search logs in Kibana, the query is executed on data nodes.

Basic configuration example:

```yaml
node.roles: [ data ]
```

List all nodes and their roles:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/nodes?v"
```

### ASCII Diagram – Data Node

```
+-----------------------+
|        Data Node      |
|-----------------------|
| Stored Documents      |
| Primary Shards        |
| Replica Shards        |
| Search & Index Load   |
+-----------------------+
```

---

### 1.3 Coordinating Node

A **coordinating node** works as a **traffic manager**. It receives requests from users or Kibana and forwards them to the correct data nodes.

Main responsibilities:

* Receives search and index requests
* Forwards requests to the correct data nodes
* Collects results from data nodes
* Sends the final result back to the client

Simple example:

* When Kibana sends a search, it usually connects to a coordinating node.

Basic configuration example:

```yaml
node.roles: []
```

### ASCII Diagram – Request Flow Through Coordinating Node

```
User / Kibana
      |
      v
+----------------------+
|  Coordinating Node   |
+----------------------+
            |
            v
     +------------+   +------------+   +------------+
     | Data Node  |   | Data Node  |   | Data Node  |
     +------------+   +------------+   +------------+
            |
            v
+----------------------+
|  Coordinating Node   |
+----------------------+
            |
            v
        Final Result
```

---

### 1.4 Ingest Node

An **ingest node** processes data **before it is stored** in Elasticsearch. It is used when data needs to be modified, cleaned, or formatted before indexing.

Main responsibilities:

* Applies ingest pipelines
* Modifies or enriches incoming data
* Prepares documents for storage

Simple example:

* Adding a timestamp field to logs before storing them.

Basic configuration example:

```yaml
node.roles: [ ingest ]
```

View ingest pipelines:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_ingest/pipeline?pretty"
```

### ASCII Diagram – Ingest Processing Flow

```
Log Source  → Coordinating Node → Ingest Node    →   Data Node
                  (Route)           (Process)         (Store)
```

---

## 2. How Clusters Handle Data Distribution

Elasticsearch is a **distributed system**. Data is split into parts called **shards** and stored across multiple data nodes.

---

### 2.1 Basic Distribution Concept

* Each index is divided into **primary shards**
* Each primary shard can have **replica shards**
* Shards are distributed across different data nodes

Benefits of this distribution:

* Faster searching
* Load sharing between nodes
* High availability

---

### 2.2 Simple Indexing Flow

1. A document is sent to the cluster
2. A coordinating node receives the request
3. The correct primary shard is selected
4. Data is stored on the primary shard
5. A copy is sent to the replica shard

---

### 2.3 Simple Search Flow

1. A search request is sent by the user
2. The coordinating node receives the request
3. The query is sent to all relevant data nodes
4. Each data node searches its shards
5. Results are returned and combined
6. Final result is sent to the user

---

### ASCII Diagram – Simple Data Distribution

```
Index: app-logs

Node 1: Primary Shard 0
Node 2: Primary Shard 1
Node 3: Replica of Shard 0
```

---

## 3. Role of Cluster State

The **cluster state** is the shared information that describes how the cluster is currently configured and running. It is maintained by the **master node**.

---

### 3.1 What Cluster State Contains

* List of all nodes in the cluster
* List of all indices
* Shard allocation details
* Index settings and mappings

---

### 3.2 How Cluster State Is Used

* All nodes keep a copy of the cluster state
* When something changes, the master node updates it
* The updated state is shared with all nodes

---

### 3.3 Why Cluster State Is Important

Without a correct cluster state:

* Nodes will not know where data is stored
* Searches will fail
* The cluster will not function properly

---

## Verification Commands

Check cluster health:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cluster/health?pretty"
```

Check node list and roles:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/nodes?v"
```

Check shard placement:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/shards?v"
```

---
