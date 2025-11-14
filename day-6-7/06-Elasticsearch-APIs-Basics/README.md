## 📅 Day 6: Elasticsearch APIs (Basics)

This module focuses on the core REST APIs for interacting with Elasticsearch. While Kibana provides a user interface, all actions (including those in Kibana) are simply API calls. We will use **Dev Tools** to execute these commands.

### 1\. REST API Basics

A REST (Representational State Transfer) API is a standard way for computer systems to communicate. Elasticsearch is "API-first," meaning every action is an API call.

All requests consist of:

1.  **The Verb:** The action to take.
      * `GET`: **Read** data (e.g., get a document, check health).
      * `PUT`: **Create or Overwrite** data at a *specific* "address" or "ID" (e.g., create an index, add a document with ID `order-123`).
      * `POST`: **Create** data at a *system-generated* "address" (e.g., add a document and let Elasticsearch assign the ID) OR **execute** a complex operation (e.g., run a search).
      * `DELETE`: **Remove** data (e.g., delete a document, delete an index).
2.  **The Path:** The "address" of the resource (e.g., `/_cluster/health`, `/orders-2020-01`).
3.  **The Body:** (Optional) A JSON payload containing instructions or data (e.g., a query, a document to index, or settings).

### 2\. Cluster & Index Monitoring APIs

These are `GET` requests used to monitor the health and status of your cluster.

#### 🚀 Hands-On: Monitoring

*Action: Run these commands in **Dev Tools**.*

**Lab 1: View Cluster Health (`GET /_cluster/health`)**
This is the "heartbeat" of your cluster.

```http
GET /_cluster/health
```

  * **Result Analysis:** The `"status"` field is the most important:
      * `"status": "green"`: All primary and replica shards are allocated.
      * `"status": "yellow"`: All primary shards are allocated, but one or more *replicas* are not. The cluster is 100% functional but not fault-tolerant. (This is normal for a single-node lab).
      * `"status": "red"`: At least one *primary* shard is unallocated. You are missing data.

**Lab 2: Check All Indices (`GET /_cat/indices`)**
The `_cat` (Compact and Aligned Text) APIs are text-based and easy for humans to read.

```http
GET /_cat/indices?v&s=index
```

  * `?v`: Adds verbose headers.
  * `&s=index`: Sorts by the `index` column.
  * **Result:** A table showing the `health`, `status`, `index` name, `docs.count`, and `store.size` of every index in your cluster.

### 3\. Document CRUD APIs

This lab covers the **CRUD (Create, Read, Update, Delete)** operations for single documents. We will create a new, clean test index that uses your `orders` template.

#### 🚀 Hands-On: CRUD Lab Setup

1.  **Action** In **Dev Tools**, create a new test index. Because its name starts with `orders`, it will automatically use your `orders` index template.
    ```http
    PUT /orders-api-test
    ```
2.  **Verify (Optional):** Check the mapping to confirm the template was applied.
    ```http
    GET /orders-api-test/_mapping
    ```
    *Result: You will see the full `orders` schema, with `dynamic: false` and all your fields.*

#### 🚀 Lab 3 Inserting Documents (POST)

Use `POST` when you want Elasticsearch to **auto-generate a unique ID** for your document.

1.  **Action:** Add a document to your new index.
    ```http
    POST /orders-api-test/_doc
    {
      "@timestamp": "2025-11-14T11:00:00Z",
      "id": "A-1001",
      "product": { "name": "Men's T-Shirt", "price": 25.00 },
      "customer": { "id": "C-001", "name": "John Doe" },
      "total": 25.00
    }
    ```
2.  **Analyze Result:** Elasticsearch will return a `result: "created"` and a unique, system-generated `_id` (e.g., `aBc1dEfG...`).

**Lab 4: Create a Document with a *Known ID* (PUT)**
To make the next labs easier, we will now add a document with an ID we can remember.

1.  **Action:** Use `PUT` to specify the ID `order-123`.
    ```http
    PUT /orders-api-test/_doc/order-123
    {
      "@timestamp": "2025-11-14T11:05:00Z",
      "id": "A-1002",
      "product": { "name": "Women's Jeans", "price": 70.00 },
      "customer": { "id": "C-002", "name": "Jane Smith" },
      "total": 70.00
    }
    ```
2.  **Result:** It will return `result: "created"` and confirm the `_id` is `order-123`.

#### 🚀 Lab 5 Updating Documents (POST vs. PUT)

This is a critical concept. There are two ways to update.

**Method 1 (PUT): The "Overwrite" Method (Destructive)**
If you use `PUT` on an existing ID, you **replace the entire document**.

1.  **Action:** Let's *try* to update the price of `order-123`.
    ```http
    PUT /orders-api-test/_doc/order-123
    {
      "total": 75.00
    }
    ```
2.  **Verify the Error:** Now `GET` the document again.
    ```http
    GET /orders-api-test/_doc/order-123
    ```
3.  **Result:** **This is a common mistake.** The `customer`, `product`, and `@timestamp` fields are *gone*. The document *only* contains `total: 75.00`. `PUT` *overwrites*, it does not merge.

**Method 2 (POST + `_update`): The "Partial Update" Method (Correct)**
This is the correct, professional way to update. It *merges* your changes.

1.  **Action:** First, re-run the `PUT` command from Lab 4 to fix the document.
2.  **Action:** Now, let's *partially update* it using the `_update` API. We will change the `total` and add a `channel`.
    ```http
    POST /orders-api-test/_update/order-123
    {
      "doc": {
        "total": 75.00,
        "channel": "Online"
      }
    }
    ```
3.  **Verify:** `GET` the document one more time.
    ```http
    GET /orders-api-test/_doc/order-123
    ```
4.  **Result:** **Success\!** The `customer`, `product`, and `@timestamp` fields are all still there. Only the `total` field was updated, and the new `channel` field was added.

#### 🚀 Lab 6 Deleting Documents by ID

This is how you delete a single document by its ID.

1.  **Action:**

    ```http
    DELETE /orders-api-test/_doc/order-123
    ```

    *Result: You will get `result: "deleted"`.*

2.  **Verify:**

    ```http
    GET /orders-api-test/_doc/order-123
    ```

    *Result: You will get `"found": false`.*

3.  **Cleanup:**

    ```http
    DELETE /orders-api-test
    ```

-----

### 4\. Searching with `_search` API

This is the API that Kibana's Discover tab uses in the background. It uses the `POST` verb because you are *executing* a complex query defined in the request body.

#### 🚀 Hands-On: `_search` API

**Task:** Search the `access-logs*` index. Find all logs that are *not* `200` (OK) and are *not* from the `system` user.

```http
POST /access-logs*/_search
{
  "query": {
    "bool": {
      "must_not": [
        { "term": { "http.response.status_code": 200 } },
        { "term": { "user_id": "system" } }
      ]
    }
  },
  "size": 5,
  "sort": [
    { "@timestamp": { "order": "desc" } }
  ]
}
```

  * **Result:** A JSON object where the `hits.hits` array contains the top 5 non-200, non-system logs, sorted with the newest ones first.