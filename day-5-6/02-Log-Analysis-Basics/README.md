## Log Analysis Basics

### Lab Setup: Ingesting New Sample Data

Before we can analyze, we must add new data that will allow us to find interesting patterns. We will add new logs to `access-logs-2020-01` and new orders to your `orders` index.

**Action:** Navigate to **Management -\> Dev Tools**. Copy and run the entire `_bulk` command below to add 12 new documents.

```http
POST /_bulk
{ "index": { "_index": "access-logs-2020-01", "_id": "la-001" } }
{ "@timestamp": "2020-01-20T10:00:00Z", "service_name": "frontend-web", "client.ip": "10.10.10.10", "http.response.status_code": 200, "user_id": "dave", "message": "User 'dave' login successful", "response_time_ms": 120 }
{ "index": { "_index": "access-logs-2020-01", "_id": "la-002" } }
{ "@timestamp": "2020-01-20T10:01:00Z", "service_name": "frontend-web", "client.ip": "10.10.10.10", "http.response.status_code": 200, "user_id": "dave", "message": "User 'dave' GET /profile", "response_time_ms": 80 }
{ "index": { "_index": "access-logs-2020-01", "_id": "la-003" } }
{ "@timestamp": "2020-01-20T10:02:00Z", "service_name": "frontend-web", "client.ip": "10.10.10.10", "http.response.status_code": 404, "user_id": "dave", "message": "User 'dave' GET /profile/image.png (Not Found)", "response_time_ms": 30 }
{ "index": { "_index": "access-logs-2020-01", "_id": "la-004" } }
{ "@timestamp": "2020-01-20T10:02:15Z", "service_name": "frontend-web", "client.ip": "10.10.10.10", "http.response.status_code": 404, "user_id": "dave", "message": "User 'dave' GET /profile/avatar.jpg (Not Found)", "response_time_ms": 28 }
{ "index": { "_index": "access-logs-2020-01", "_id": "la-005" } }
{ "@timestamp": "2020-01-20T10:05:00Z", "service_name": "api-gateway", "client.ip": "8.8.8.8", "http.response.status_code": 404, "message": "GET /v1/invalid (Not Found)", "response_time_ms": 45 }
{ "index": { "_index": "access-logs-2020-01", "_id": "la-006" } }
{ "@timestamp": "2020-01-20T10:05:05Z", "service_name": "api-gateway", "client.ip": "8.8.8.8", "http.response.status_code": 404, "message": "GET /v1/old (Not Found)", "response_time_ms": 42 }
{ "index": { "_index": "access-logs-2020-01", "_id": "la-007" } }
{ "@timestamp": "2020-01-20T10:05:10Z", "service_name": "api-gateway", "client.ip": "8.8.8.8", "http.response.status_code": 404, "message": "GET /v1/test (Not Found)", "response_time_ms": 44 }
{ "index": { "_index": "access-logs-2020-01", "_id": "la-008" } }
{ "@timestamp": "2020-01-20T10:08:00Z", "service_name": "payment-service", "client.ip": "10.10.10.10", "http.response.status_code": 503, "user_id": "dave", "message": "Service Unavailable. Payment API is down.", "response_time_ms": 5200 }
{ "index": { "_index": "access-logs-2020-01", "_id": "la-009" } }
{ "@timestamp": "2020-01-20T10:08:02Z", "service_name": "payment-service", "client.ip": "10.10.10.10", "http.response.status_code": 503, "user_id": "dave", "message": "Service Unavailable. Payment API is down.", "response_time_ms": 5100 }
{ "index": { "_index": "access-logs-2020-01", "_id": "la-010" } }
{ "@timestamp": "2020-01-20T10:08:05Z", "service_name": "payment-service", "client.ip": "10.10.10.10", "http.response.status_code": 503, "user_id": "dave", "message": "Service Unavailable. Payment API is down.", "response_time_ms": 5300 }
{ "index": { "_index": "orders", "_id": "la-ord-001" } }
{ "@timestamp": "2020-01-20T10:01:30Z", "id": "ORD-DAVE-001", "product": { "id": "P-123", "name": "Men's T-Shirt", "price": 25.0, "brand": "Active Life", "category": "Clothing" }, "customer.id": "dave", "customer.age": 34, "customer.gender": "male", "customer.name": "Dave Liu", "channel": "Online", "discount": 5.0, "total": 20.0 }
{ "index": { "_index": "orders", "_id": "la-ord-002" } }
{ "@timestamp": "2020-01-20T10:09:00Z", "id": "ORD-DAVE-002", "product": { "id": "P-456", "name": "Laptop", "price": 1200.0, "brand": "TechCorp", "category": "Electronics" }, "customer.id": "dave", "customer.age": 34, "customer.gender": "male", "customer.name": "Dave Liu", "channel": "Online", "discount": 120.0, "total": 1080.0 }
```

*Result: You have successfully added 10 new log entries and 2 new orders.*

-----

### Spotting Spikes in Errors

**Conceptual Overview:**
A "spike" is a sudden, visual increase in the count of logs in the **Discover Histogram**. This is the automatic bar chart at the top of the Discover page. This chart is dynamic and redraws itself to reflect your KQL query, allowing you to visually pinpoint the exact time an error spike occurred.

**Hands-On Lab: Visual Analysis of Our New Spike**

1.  **Action:** Navigate to **Discover** and select the **`access-logs*`** index pattern.
2.  **Action:** Set the **Time Picker** to a narrow range around our new data.
      * **Start:** `2020-01-20T09:55:00Z`
      * **End:** `2020-01-20T10:15:00Z`
      * Click **Update**.
3.  **Analyze:** Look at the **Histogram**. You will see several bars with a `count` of 1 or 2, but you will see two prominent spikes:
      * One spike (count of 3) around `10:05`
      * One spike (count of 3) around `10:08`
4.  **Action:** Let's isolate the *error* spike. In the KQL search bar, enter the **correct** range query (a wildcard `5*` will not work on a `long` field):
    ```kql
    http.response.status_code >= 500 and http.response.status_code <= 599
    ```
5.  **Analyze:** The **Histogram** updates. The `10:05` spike (which was `404` errors) disappears. The *only* bar left is the one at `10:08` with a count of 3. You have now confirmed and isolated your *server error* spike.
6.  **Action:** Clear the KQL bar. Click and drag your mouse on the histogram just around the `10:08` spike (e.g., from `10:07:00` to `10:09:00`).
7.  **Analyze:** The **Time Picker** and **Document Table** update. You can now see the three `503` error logs (`la-008`, `la-009`, `la-010`) and can confirm they all belong to `user_id: "dave"`.

-----

### Tracking Top IP Addresses

**Conceptual Overview:**
A common question is "Who is hitting my server?" or "Which client is causing all these errors?" The **Field List** on the left side of Discover dynamically calculates the "Top 5" values for `keyword` fields based on your current query.

**Hands-On Lab: Finding "Top Offenders"**

1.  **Action:** In **Discover**, select the `access-logs*` pattern and set the Time Picker to the `2020-01-20T10:00:00Z` to `2020-01-20T10:15:00Z` range.
2.  **Task:** Find the IP address responsible for the most `404` errors.
3.  **Action (KQL):** In the search bar, type `http.response.status_code: 404` and press Enter.
4.  **Analyze:** The document table filters to show *only* `404` logs (our logs `la-003`, `la-004`, `la-005`, `la-006`, `la-007`).
5.  **Action:** Now, look at the **Field List** on the left and find `client.ip`. Click it to expand.
6.  **Analyze:** The Top 5 list has dynamically updated. It no longer shows the "Top Talkers" overall; it now shows the **Top 5 IPs responsible for `404` errors**. You will see:
      * `8.8.8.8` (3 hits)
      * `10.10.10.10` (2 hits)
        You have instantly identified the "top offender."

-----

### Checking User Activity

**Conceptual Overview:**
This is the "needle in a haystack" workflow. A user (or IP) has been identified, and you need to see *everything* they did. By filtering for a single user, you can isolate their activity and see their session from beginning to end, sorted by time.

**Hands-On Lab: Tracing User "dave"**

1.  **Action:** Select the `access-logs*` index pattern. Set the time to our 15-minute window.
2.  **Action:** Clear all KQL queries. We will use a filter pill.
3.  **Task:** Find all activity for `user_id: "dave"`.
4.  **Action (Filter):** In the **Field List**, find and click `user_id`.
5.  Hover over `dave` and click the **`+` (Filter for value)** icon.
6.  **Analyze:** A filter pill `user_id is "dave"` is added. The document table now shows *only* logs from this user, sorted by time. You can read their `url.path` actions like a story:
      * `10:00:00` - Login (Success)
      * `10:01:00` - `GET /profile` (Success)
      * `10:02:00` - `GET /profile/image.png` (404)
      * `10:02:15` - `GET /profile/avatar.jpg` (404)
      * `10:08:00` - `payment-service` (503)
      * `10:08:02` - `payment-service` (503)
      * `10:08:05` - `payment-service` (503)
        You have a complete audit trail of this user's very bad session.

-----

### Identifying Slow Response Times

**Conceptual Overview:**
Site performance is a critical metric. Your `access-logs` schema contains the `response_time_ms` field (a `long`). We can analyze this field to find bottlenecks.

**Hands-On Lab: Finding Slow Requests**

1.  **Action:** Select the `access-logs*` index pattern. Keep the same time range.

2.  **Task:** Find all requests that took longer than 5 seconds (5000 milliseconds).

3.  **Action (KQL):** In the search bar, type `response_time_ms > 5000` and press Enter.

4.  **Analyze:** The document table instantly filters to show *only* our three "payment-service" errors (`la-008`, `la-009`, `la-010`), which took 5200ms, 5100ms, and 5300ms.

5.  **Task:** Find the *single slowest* request in this user's session.

6.  **Action:** First, filter for the user (`user_id is "dave"`). Clear the KQL bar.

7.  **Action (Customize Table):** In the Field List, add the `response_time_ms` field as a column to your document table (click the `+` button).

8.  **Action (Sort):** Click the **header** of the `response_time_ms` column in the table. It will sort ascending (fastest). Click the header **again**.

9.  **Analyze:** The table is now sorted *descending* (slowest to fastest). The very first log (`la-010` at 5300ms) is the single slowest request in this user's session.

-----

### Adding Scripted Field (Basic Calculation)

**Conceptual Overview:**
Sometimes, your data is not in the perfect format. Your `orders` data has `product.price` and `discount`, but you really want to know the *final sale price*.

A **Scripted Field** is a *virtual* field that you create *inside Kibana*. It does **not** change your original data. It runs a calculation on-the-fly at query time. It uses a language called **Painless**.

**Hands-On Lab: Create a "Final Price" Field**

1.  **Action:** Navigate to **Stack Management** (☰ -\> Management -\> Stack Management).

2.  **Action:** Click **Index Patterns** (under Kibana).

3.  **Action:** Click the `orders*` pattern name to open its settings.

4.  **Action:** Click the **"Scripted fields"** tab (next to the "Fields" tab).

5.  **Action:** Click **"Add scripted field"** (or "Create scripted field").

6.  **Action:** Fill out the form:

      * **Name:** `final_price`
      * **Language:** `painless`
      * **Type:** `number`
      * **Format:** `Number` (leave as default)
      * **Script:** This is the logic. We must safely access both fields and perform the calculation.

    <!-- end list -->

    ```painless
    // Check if both fields exist. If not, return 0.
    if (doc['product.price'].size() == 0 || doc['discount'].size() == 0) {
      return 0;
    }

    // Perform the calculation and return the value
    double price = doc['product.price'].value;
    double disc = doc['discount'].value;

    // Ensure price is not negative
    if (price - disc < 0) {
      return 0;
    } else {
      return price - disc;
    }
    ```

7.  **Action:** Click **Save field**.

8.  **Action (Use Your New Field):**

      * Navigate back to **Discover** and select the **`orders*`** index pattern.
      * Set your time range to include `2020-01-20`.
      * In the **Field List**, you will now see your *new* virtual field: `final_price`.
      * **Action (Customize Table):** Add `product.price`, `discount`, and your new `final_price` to the document table.
      * **Analyze:** You can now see the original price, the discount, and your new calculated `final_price`, all side-by-side (e.g., 25.0 - 5.0 = 20.0).
      * **Action (Query the Field):** In the KQL bar, type `final_price > 1000`. This will correctly find `la-ord-002` (1080.0).