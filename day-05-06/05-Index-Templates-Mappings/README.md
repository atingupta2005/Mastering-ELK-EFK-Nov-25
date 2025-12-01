## 📅 Day 6: Index Templates & Mappings

### 1\. What is an Index Template?

An **Index Template** is a "blueprint" that Elasticsearch uses to automatically configure *new* indices at the moment they are created. It is the single most important component for managing your data in a scalable, consistent way.

An index template is **not** an index; it is a set of rules that are applied *at the moment* a new index is created.

A template consists of two main parts:

1.  **`index_patterns`**: An array of wildcard patterns. This tells the template *which* new indices it should apply itself to.
      * **Example:** `"index_patterns": ["access-logs*"]` will match any new index named `access-logs-2025-01`, `access-logs-prod`, etc.
2.  **`template`**: A body containing the `settings` and `mappings` that should be applied to the new index.
      * `settings`: Configures the "physical" aspects of the index (e.g., number of shards, number of replicas).
      * `mappings`: Configures the "schema" of the index (e.g., field names and data types).

-----

### 2\. Why Templates are Useful (Consistency Across Indices)

The primary benefit of a template is **enforced consistency**.

Consider a time-based logging setup:

  * `access-logs-2025-11` (November's data)
  * `access-logs-2025-12` (December's data)

**The Problem:** What if in November, Elasticsearch *guessed* that `http.response.status_code` was a `number` (from `200`), but on December 1st, the first log it saw was `"N/A"`, making it guess `keyword`?

  * Your two indices now have *conflicting schemas*.
  * When you run a search in Kibana for `http.response.status_code > 400`, the search will **fail** on the December index.
  * All your dashboards for "HTTP Status" will break.

**The Solution:** An index template *enforces* the same rules on both indices. By using the `access-logs` template, you guarantee that `http.response.status_code` is *always* mapped as a `long` in *every* new `access-logs*` index, forever. This ensures that your data structure is 100% consistent and your Kibana dashboards will never break.

-----

### 3\. Creating a Simple Index Template

This hands-on lab will create a new, simple template from scratch.

#### 🚀 Hands-On: Create a "Metrics" Template

1.  **Action:** Navigate to **Management** -\> **Dev Tools**.

2.  **Action:** Run the following command to create a template for a new data source, `my-metrics-*`. This template will ensure all metrics indices have one shard and the correct mappings.

    ```http
    PUT /_index_template/my-simple-metrics-template
    {
      "index_patterns": ["my-metrics-*"],
      "template": {
        "settings": {
          "number_of_shards": 1,
          "number_of_replicas": 0
        },
        "mappings": {
          "properties": {
            "@timestamp": { "type": "date" },
            "service.name": { "type": "keyword" },
            "host.name": { "type": "keyword" },
            "cpu.usage.pct": { "type": "float" }
          }
        }
      }
    }
    ```

    *Result: You will get an `"acknowledged": true`. The "blueprint" is now saved.*

3.  **Action (Verification):** Now, let's trigger this template by creating a *new index* that matches the pattern.

    ```http
    PUT /my-metrics-test-001
    ```

4.  **Action (Verification):** Let's check the schema of the index that was just created.

    ```http
    GET /my-metrics-test-001/_mapping
    ```

    *Result: You will see that even though you created an empty index, Elasticsearch automatically applied your template. The `mappings` section will show the `cpu.usage.pct` as a `float` and `host.name` as a `keyword`, just as you defined.*

5.  **Action (Cleanup):**

    ```http
    DELETE /my-metrics-test-001
    DELETE /_index_template/my-simple-metrics-template
    ```

-----

### 4\. Field Mappings Explained

"Mappings" are the "schema" for your index. This is the `properties` block inside your template. It defines every single field, its data type, and (optionally) how it should be indexed.

A mapping can be simple, like `id: { "type": "keyword" }`.

It can also be a complex, nested JSON object. The `orders` template is a perfect example of this, where `product` is an `object` that has its *own* `properties`:

```json
"product": {
  "properties": {
    "id": { "type": "keyword" },
    "name": { "type": "keyword" },
    "price": { "type": "float" },
    "brand": { "type": "keyword" },
    "category": { "type": "keyword" }
  }
}
```

This allows you to run "dot notation" queries, such as `product.brand: "Active Life"`.

-----

### 5\. Common Data Types (string, keyword, date, number)

Choosing the correct data type is the most important decision you will make, as it controls performance, storage, and search capabilities.

| Data Type | Elasticsearch Type(s) | **Use Case (The "Why")** | Example(s) from Your Templates |
| :--- | :--- | :--- | :--- |
| **Keyword** | `keyword` | **Filtering, Sorting, Aggregating.** Use for "exact" values. | `http.request.method`, `client.geo.country_name`, `product.brand`, `user_id` |
| **Text** | `text` | **Full-Text Search.** Use for human-readable sentences. This data is "analyzed" (e.g., "Login Failed" is stored as `[login]`, `[failed]`). | `message`, `url.original.text` (a text sub-field) |
| **Number** | `long`, `float`, `short`, `byte` | **Math.** Use for range queries (`> 100`) or numeric aggregations (`avg()`, `sum()`). | `http.response.body.bytes` (long), `product.price` (float), `customer.age` (short) |
| **Date** | `date` | **Time-Based Filtering.** Enables the Time Picker in Kibana. | `@timestamp` |
| **IP** | `ip` | **IP Range Filtering.** Allows CIDR queries (e.g., `192.168.0.0/16`). | `client.ip` |
| **Geo** | `geo_point` | **Maps.** Allows you to plot coordinates on a map in Kibana. | `client.geo.location` |

-----

### 6\. Default Mapping vs. Explicit Mapping

This is a critical concept of data quality.

  * **Default (Dynamic) Mapping:** This is what happens when you `POST` a document to an index that *does not exist* and for which there is *no template*. Elasticsearch will create the index and *guess* the mappings based on the first document it sees.

      * **The Problem:** If the first document has `"http_status": "200"` (a string), Elasticsearch will map that field as `text`. Every subsequent document, even if it has `http_status: 500` (a number), will be *forced* to be `text`. Your ability to aggregate or run range queries on that field is lost forever.
      * This is "easy mode" and is **bad for production**.

  * **Explicit Mapping (Your Templates):** This is the professional way. You define the schema *in advance* using an Index Template.

      * The `access-logs` and `orders` templates use two advanced settings to enforce this:

    <!-- end list -->

    1.  **`"dynamic": false`**: This **disables** dynamic mapping. If a document arrives with a *new, unknown* field (e.g., `my_new_field: "test"`), Elasticsearch will **REJECT** the entire document. This protects your schema from being polluted.
    2.  **`"index.mapping.coerce": false`**: This **disables** type conversion. If you try to index a document where `total` is a `string` (`"50.99"`) but the mapping is `float`, Elasticsearch will **REJECT** the document. This enforces data quality.

-----

### 7\. Adding New Fields to an *Existing* Index

**The Scenario:** Your `access-logs-2020-01` index already exists. Your developers are now adding a *new* field, `http.request.tracking_id`, to their logs. Your `dynamic: false` setting is correctly rejecting this new field. You must *explicitly* tell Elasticsearch to allow it.

**Action:** You must use the `PUT /<index>/_mapping` API. This command is *non-destructive* and will add the new field without harming existing data.

#### 🚀 Hands-On: Update an Existing Index's Mapping

1.  **Action:** Go to **Dev Tools**.

2.  **Action:** Run this command to add the `http.request.tracking_id` field *only* to the `access-logs-2020-01` index.

    ```http
    PUT /access-logs-2020-01/_mapping
    {
      "properties": {
        "http.request.tracking_id": {
          "type": "keyword"
        }
      }
    }
    ```

    *Result: `"acknowledged": true`.*

3.  **Action (Verification):**

    ```http
    GET /access-logs-2020-01/_mapping
    ```

    *Result: You will see your new `http.request.tracking_id` field is now part of the schema for *this index only*.*

-----

### 8\. Updating Templates for *New* Indices

**The Problem:** You solved the problem from Topic 7, but *only* for the `access-logs-2020-01` index. When the next month's index, `access-logs-2020-04`, is created, it will *fail* because it will be built from the *old* template that doesn't have the `tracking_id`.

**The Solution:** You must update the **Index Template** itself, so all *future* indices are created with the new field.

#### 🚀 Hands-On: Update the `access-logs` Template

1.  **Action:** Go to **Dev Tools**.

2.  **Action:** You must `PUT` the *entire, complete, updated* template. You cannot just send the new field.
    *This command shows the *full* `access-logs` template, with the new field added (near the bottom).*

    ```http
    PUT /_index_template/access-logs
    {
      "index_patterns": ["access-logs*"],
      "template": {
        "settings": {
          "index.mapping.coerce": false
        },
        "mappings": {
          "dynamic": false,
          "properties": {
            "@timestamp": { "type": "date" },
            "message": { "type": "text" },
            "event.dataset": { "type": "keyword" },
            "hour_of_day": { "type": "short" },
            "http.request.method": { "type": "keyword" },
            "http.request.referrer": { "type": "keyword" },
            
            "http.request.tracking_id": { "type": "keyword" },  <-- OUR NEW FIELD
            
            "http.response.body.bytes": { "type": "long" },
            "http.response.status_code": { "type": "long" },
            "http.version": { "type": "keyword" },
            "url.fragment": { "type": "keyword" },
            "url.path": { "type": "keyword" },
            "url.query": { "type": "keyword" },
            "url.scheme": { "type": "keyword" },
            "url.username": { "type": "keyword" },
            "url.original": {
              "type": "keyword",
              "fields": { "text": { "type": "text", "norms": false } }
            },
            "client.address": { "type": "keyword" },
            "client.ip": { "type": "ip" },
            "client.geo.city_name": { "type": "keyword" },
            "client.geo.continent_name": { "type": "keyword" },
            "client.geo.country_iso_code": { "type": "keyword" },
            "client.geo.country_name": { "type": "keyword" },
            "client.geo.location": { "type": "geo_point" },
            "client.geo.region_iso_code": { "type": "keyword" },
            "client.geo.region_name": { "type": "keyword" },
            "user_agent.device.name": { "type": "keyword" },
            "user_agent.name": { "type": "keyword" },
            "user_agent.version": { "type": "keyword" },
            "user_agent.original": {
              "type": "keyword",
              "fields": { "text": { "type": "text", "norms": false } }
            },
            "user_agent.os.version": { "type": "keyword" },
            "user_agent.os.name": {
              "type": "keyword",
              "fields": { "text": { "type": "text", "norms": false } }
            },
            "user_agent.os.full": {
              "type": "keyword",
              "fields": { "text": { "type": "text", "norms": false } }
            }
          }
        }
      }
    }
    ```

3.  **Result:** You get an `"acknowledged": true`. The `access-logs` "blueprint" is now updated.

4.  **Conclusion:** This update does **not** affect any existing indices. However, the *next* time a new index is created (e.g., `access-logs-2020-04`), it will be built from this new template and will automatically include the `http.request.tracking_id` field.