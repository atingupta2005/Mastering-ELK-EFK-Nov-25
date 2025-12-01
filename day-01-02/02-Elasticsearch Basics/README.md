## Elasticsearch Basics

### 6\. Index and Document explained (with SQL analogy)

In Elasticsearch, there are two core concepts you must understand: **Documents** and **Indices**.

  * **📄 Document:** This is the basic unit of information that you store. It is a single record, similar to a *row* in a SQL table.
  * **🗄️ Index:** This is a collection of similar documents. It is similar to a *database* (or a *table*) in the SQL world.

The most common analogy is to a traditional SQL database:

| **Elasticsearch World** | **SQL World** | **Practical Example** |
| :--- | :--- | :--- |
| `Index` | `Database` or `Table` | `web_logs` |
| `Document` | `Row` | A single log line or event |
| `Field` | `Column` | `http_status_code` |

**Text Diagram: SQL vs. Elasticsearch**

```text
    SQL DATABASE (e.g., "company_db")            ELASTICSEARCH INDEX (e.g., "user_index")
    ┌───────────────────────────────────┐         ┌───────────────────────────────────────┐
    │ TABLE (e.g., "users")             │         │ {                                     │
    ├───────────────────────────────────┤         │   "name": "John Doe",                  │
    │ ID │ Name     │ Email             │         │   "email": "john.doe@example.com",     │
    ├───────────────────────────────────┤         │   "id": "1"                           │
    │ 1  │ John Doe │ john.doe@ex...  │◀──Row    │ } ◀── DOCUMENT 1                      │
    │ 2  │ Jane Smith│ jane.smith@ex...│         │                                       │
    └───────────────────────────────────┘         │ {                                     │
         ▲                                        │   "name": "Jane Smith",                │
         │                                        │   "email": "jane.smith@example.com",   │
         │                                        │   "id": "2"                           │
       Column                                     │ } ◀── DOCUMENT 2                      │
    (e.g., "Name")                                └───────────────────────────────────────┘
                                                            ▲
                                                            │
                                                          FIELD (e.g., "name")
```

-----

### 7\. JSON structure of a document

An Elasticsearch **Document** is not just *like* a JSON object—it **is** a JSON object.

JSON (JavaScript Object Notation) is the standard format for data in Elasticsearch. It uses simple **key: value** pairs, which makes it incredibly flexible.

**Practical Example: A Sample Log Document**

Instead of a messy, single-line log like this:
`192.168.1.10 - "GET /login HTTP/1.1" 200 1452 "http://example.com" "Mozilla/5.0..."`

You store it in Elasticsearch as a clean JSON document, where every piece of information is a named **field**:

```json
{
  "@timestamp": "2025-11-09T10:45:00.000Z",
  "client_ip": "192.168.1.10",
  "http_method": "GET",
  "url_path": "/login",
  "http_status": 200,
  "bytes_sent": 1452,
  "referrer": "http://example.com",
  "user_agent": "Mozilla/5.0...",
  "tags": ["production", "webserver", "login_attempt"]
}
```

**Key benefits of this structure:**

  * **Flexible Schema:** You can add or remove fields easily. Need to add `"user_id": 123`? Just send it in the next document.
  * **Searchable:** You can now run very specific queries, like `http_status: 200 AND http_method: "GET"`.
  * **Human-Readable:** It's easy for you (and Kibana) to read and understand the data.

-----

### 8\. Fields and common data types

A **Field** is simply a **key** in the JSON document (e.g., `"http_status"`). Each field must have a specific **data type** (called a "mapping").

Choosing the correct data type is the **most important** part of setting up an index. It tells Elasticsearch how to store and, more importantly, *how to index* the data.

Here are the most common data types you will use:

| Data Type | Description | Practical Example | Why? |
| :--- | :--- | :--- | :--- |
| `text` | For full-text search. The data is **analyzed** (broken into individual words, lowercased, etc.). | `error_message: "User login failed"` | So you can search for "login" or "failed" and find this document. |
| `keyword` | For exact-match search. The data is **not analyzed**; it's treated as one single "tag". | `http_status: 200` <br> `client_ip: "192.168.1.10"` <br> `tags: ["prod"]` | So you can search for the *exact* value `200` or `"192.168.1.10"`. You don't want to find "192" or "168". |
| `date` | For dates and times. Stored in a format that allows for fast range queries. | `@timestamp: "2025-11-09T10:45:00Z"` | So you can ask, "Show me all logs from the last 15 minutes." |
| `long` / `integer` | For whole numbers. | `bytes_sent: 1452` | So you can do math, e.g., "Show me the *average* bytes\_sent" or "Find logs where bytes\_sent \> 1000". |
| `float` / `double` | For decimal numbers. | `response_time: 0.253` | Same as above; allows for mathematical operations. |

**Critical Concept: `text` vs. `keyword`**

This is the \#1 point of confusion for beginners.

  * Use **`text`** for *human-readable sentences* you want to search *inside of*.
      * **Example Field:** `email_body`, `product_description`, `log_message`
  * Use **`keyword`** for *exact values* you want to filter, sort, or aggregate on.
      * **Example Field:** `email_sender`, `product_id`, `http_status_code`, `user_name`

-----

### 9\. Primary shards and replica shards (intro only)

Elasticsearch is **distributed**, which means it's designed to run on multiple servers (nodes). **Shards** are how it achieves this.

  * **Why do shards exist?** An index (like `web_logs`) could grow to be many terabytes (TB). This is too large to fit on one server's disk.
  * **What is a shard?** A shard is a *slice* of your index. Instead of storing the whole index on one node, Elasticsearch splits it into pieces (shards) and spreads those pieces across many nodes in your cluster.

There are two types of shards:

1.  **🔵 Primary Shard:**

      * When you create an index, you decide how many primary shards it has (e.g., 2).
      * Elasticsearch will *split* your data across these primary shards. (e.g., Documents 1-500 go to Primary 0, Documents 501-1000 go to Primary 1).
      * You **cannot** change the number of primary shards after you create the index.

2.  **🟢 Replica Shard (Replica):**

      * A replica is an *exact copy* of a primary shard.
      * Its job is to provide **High Availability (HA)** and **Search Performance**.

**Text Diagram: Index with 2 Primary Shards and 1 Replica**

This shows a 3-node cluster. Notice how Elasticsearch automatically places the replica on a *different* node than its primary to prevent data loss.

```text
       ┌──────────────────────────┐          ┌──────────────────────────┐          ┌──────────────────────────┐
       │         NODE 1           │          │         NODE 2           │          │         NODE 3           │
       │                          │          │                          │          │                          │
       │   ┌──────────────────┐   │          │   ┌──────────────────┐   │          │   ┌──────────────────┐   │
       │   │   Primary 0 (P0) │   │          │   │   Primary 1 (P1) │   │          │   │   Replica 0 (R0) │   │
       │   │ (Copy of P1)     │   │          │   │ (Copy of P0)     │   │          │   │ (Copy of P1)     │   │
       │   │   Replica 1 (R1) │   │          │   │   Replica 0 (R0) │   │          │   │   Replica 1 (R1) │   │
       │   └──────────────────┘   │          │   └──────────────────┘   │          │   └──────────────────┘   │
       └──────────────────────────┘          └──────────────────────────┘          └──────────────────────────┘
```

  * **Scenario 1 (High Availability):** `Node 2` suddenly dies.
  * **Result:** Elasticsearch instantly promotes `Replica 1 (R1)` (on Node 1 or 3) to become the new `Primary 1`. No data is lost, and your application can keep writing data.
  * **Scenario 2 (Search Performance):** A search request comes in.
  * **Result:** The cluster can run the search on `P0` *and* `R1` (or `P1` and `R0`) at the same time, doubling your search throughput.

-----

### 10\. Roles in cluster: master, data, coordinating (overview)

  * A **Node** is a single server running Elasticsearch.
  * A **Cluster** is a group of one or more nodes working together.

In a cluster, not all nodes do the same job. Each node is assigned **roles**. In a large cluster, you dedicate nodes to specific roles for stability and performance.

Here are the main roles:

| Role | Nickname | What does it do? (Overview) |
| :--- | :--- | :--- |
| **Cluster Manager** <br> (aka "Master") | The "Boss" | 🧠 Manages the overall cluster health and state. <br> 🔹 Decides which nodes to create new shards on. <br> 🔹 Tracks which nodes are alive or dead. <br> 🔹 **Does NOT** handle search or indexing data. |
| **Data** | The "Worker" | 💾 **Stores the data** (the shards). <br> 🔹 Does the heavy lifting: indexing new documents and running searches on its local data. <br> 🔹 Uses lots of CPU, RAM, and *fast* disk (SSD). |
| **Coordinating** <br> (aka "Client") | The "Receptionist" | 🗣️ Receives the search request from the user/Kibana. <br> 🔹 **Does NOT** store data. <br> 🔹 Broadcasts the search to all the correct `Data` nodes. <br> 🔹 Gathers all the results and sends one final response back to the user. |

**Practical Example:**

  * **Small Cluster (1-3 nodes):** Every node does *all* roles (Master, Data, Coordinating). This is fine for development or small workloads.
  * **Large Production Cluster (e.g., 50 nodes):**
      * **3x Dedicated Master Nodes:** (Stable, low-resource nodes. Their only job is to be the "boss").
      * **40x Dedicated Data Nodes:** (Huge servers with lots of RAM and fast SSDs. They only do the "worker" job).
      * **7x Dedicated Coordinating Nodes:** (High CPU/RAM nodes. They only do the "receptionist" job, handling 1000s of incoming requests per second).