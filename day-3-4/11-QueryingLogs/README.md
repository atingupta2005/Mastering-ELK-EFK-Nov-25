## 📅 Querying Logs: Mastering the KQL Search Bar

### 1. Basics of Kibana Query Language (KQL)

#### Conceptual Overview
KQL is the text-based language you type into the search bar at the top of the Discover, Dashboard, and Visualize pages. It is designed to be simple, like a search engine, but with the power to be very specific.

There are two fundamental types of searches you can perform:

1.  **Free-Text Search (Broad)**
    * **What it is:** Typing a simple word or phrase, like `failed` or `Chrome`.
    * **How it works:** Kibana searches *all* fields in the index that are mapped as `text` (analyzed). Based on your `access-logs` template, a search for `failed` will search `message`, `url.original.text`, `user_agent.original.text`, etc.
    * **When to use it:** This is for "best guess" or "Google-style" searches when you don't know the exact field to look in.

2.  **Field-Based Search (Precise)**
    * **What it is:** Specifying the exact field and value you are looking for, using the syntax `field: value`.
    * **Example:** `http.response.status_code: 404`
    * **How it works:** This is far more efficient. It *only* searches the `http.response.status_code` field for the value `404`.
    * **When to use it:** 99% of the time. This is the professional, standard way to query data.

---

### 2. Searching Specific Fields

#### Conceptual Overview
This is the core of KQL. The syntax is always `field: value`. The behavior of the search depends on the field's data type (e.g., `keyword`, `text`, `long`, `ip`).

####  Hands-On: Field-Based Searches

**Prerequisite:** Navigate to **Discover** (☰ -> Analytics -> Discover). Set your Time Picker to `January 1, 2020` to `April 1, 2020`.

**Lab 1: Searching `keyword` Fields (Exact Match)**
* **Action:** Select the `access-logs*` index pattern.
* **Task:** Find all requests made by the `curl` user agent.
* **KQL:** `user_agent.name: "curl"`
    * (Quotes are optional for single words but good practice. They are *required* for values with spaces, e.g., `client.geo.country_name: "United States"`).
* **Result:** A precise list of logs where the `user_agent.name` is exactly "curl".

**Lab 2: Searching `text` Fields (Full-Text Match)**
* **Action:** Select the `access-logs*` index pattern.
* **Task:** Find all logs that contain the word "login" in the `message` field.
* **KQL:** `message: login`
* **Result:** A list of logs like "Successful login for user..." and "Failed login attempt...".

**Lab 3: Searching `numeric` Fields (Exact Match)**
* **Action:** Select the `access-logs*` index pattern.
* **Task:** Find all "Not Found" errors.
* **KQL:** `http.response.status_code: 404`
* **Result:** A precise list of all `404` logs.

**Lab 4: Searching `ip` Fields**
* **Action:** Select the `access-logs*` index pattern.
* **Task:** Find all logs from a specific IP address.
* **KQL:** `client.ip: "198.51.100.1"`
* **Result:** A list of all logs from that IP.

**Lab 5: Searching Nested (`object`) Fields**
* **Action:** Select the `orders*` index pattern.
* **Task:** Find all sales for a specific product brand.
* **KQL:** `product.brand: "Active Life"` (Adjust value to match your data)
* **Result:** KQL uses "dot notation" to search nested JSON objects, making it easy to query fields like `product.brand` or `customer.gender`.

---

### 3. Simple AND / OR / NOT Queries

#### Conceptual Overview
KQL allows you to combine multiple queries using simple logical operators: `and`, `or`, and `not`. You can also group them with parentheses `()`.

####  Hands-On: Combining Queries

**Lab 1: `and` (Implicit and Explicit)**
* **Action:** Select the `access-logs*` index pattern.
* **Task:** Find all `POST` requests that resulted in a `500` error.
* **KQL (Implicit):** `http.request.method: POST http.response.status_code: 500` (A space is treated as `and`).
* **KQL (Explicit):** `http.request.method: POST and http.response.status_code: 500` (This is clearer to read).
* **Result:** A highly specific list of failed `POST` requests.

**Lab 2: `or`**
* **Action:** Select the `access-logs*` index pattern.
* **Task:** Find all critical server errors (`500` or `503`).
* **KQL:** `http.response.status_code: 500 or http.response.status_code: 503`
* **Result:** A list of all logs with *either* a `500` or `503` status.

**Lab 3: `not`**
* **Action:** Select the `access-logs*` index pattern.
* **Task:** Find all logs from `Chrome` users that were *not* successful (not a 200).
* **KQL:** `user_agent.name: "Chrome" and not http.response.status_code: 200`
* **Result:** A list of all `404s`, `500s`, `401s`, etc., experienced *only* by Chrome users.

**Lab 4: Grouping with `()` (Advanced Logic)**
* **Action:** Select the `access-logs*` index pattern.
* **Task:** Find all `401` (Unauthorized) or `403` (Forbidden) logs, but *only* if they were `POST` requests.
* **KQL:** `(http.response.status_code: 401 or http.response.status_code: 403) and http.request.method: POST`
* **Result:** This query finds potential malicious activity by correctly grouping the "OR" logic first.

**Lab 5: Grouping with `orders*` data**
* **Action:** Select the `orders*` index pattern.
* **Task:** Find all sales from "Brenda Nguyen" (adjust name) that were in the "Electronics" *or* "Clothing" category.
* **KQL:** `salesman.name: "Brenda Nguyen" and (product.category: "Electronics" or product.category: "Clothing")`
* **Result:** A precise list of that salesperson's performance in key categories.

---

### 4. Range Queries (Numeric, Date)

#### Conceptual Overview
KQL uses simple operators (`>`, `>=`, `<`, `<=`) to query ranges. This is extremely useful for numeric and date fields.

####  Hands-On: Range Queries

**Lab 1: Numeric Range (`long` field)**
* **Action:** Select the `access-logs*` index pattern.
* **Task:** Find all "large downloads" (e.g., requests with a response body over 10,000 bytes).
* **KQL:** `http.response.body.bytes > 10000`
* **Result:** A list of all logs for large file transfers.

**Lab 2: Numeric Range (`float` and `short` fields)**
* **Action:** Select the `orders*` index pattern.
* **Task:** Find all high-value sales (over $150).
* **KQL:** `total > 150`
* **Result:** A list of all high-value orders.

**Lab 3: Combined Numeric Range**
* **Action:** Select the `orders*` index pattern.
* **Task:** Find all sales made to customers in a specific demographic (e.g., age 30 to 40).
* **KQL:** `customer.age >= 30 and customer.age <= 40`
* **Result:** A targeted list for demographic analysis.

**Lab 4: Date Range (in KQL)**
* **Concept:** While it is *always* easier to use the Time Picker UI, you *can* specify a time range in KQL. This is useful for fixed reports.
* **Action:** Select the `access-logs*` index pattern.
* **Task:** Find all logs from a specific 5-minute window on January 15th, 2020.
* **KQL:** `@timestamp >= "2020-01-15T10:00:00" and @timestamp <= "2020-01-15T10:05:00"`
* **Result:** The document table will show *only* logs from that 5-minute block.

---

### 5. Phrase Search ("error 404")

#### Conceptual Overview
This is a critical concept for `text` fields. By default, KQL treats words in a free-text search as an `or`.

* **Term Search (Broad):** `message: failed login`
    * **Result:** Finds logs with `failed` OR `login`.
* **Phrase Search (Precise):** `message: "failed login"`
    * **Result:** Finds *only* logs with the exact phrase "failed login".

####  Hands-On: Phrase Searches

**Lab 1: Term Search (Broad `or`)**
* **Action:** Select the `access-logs*` index pattern.
* **Task:** Search for the words `Invalid` and `password`.
* **KQL:** `message: Invalid password` (no quotes)
* **Result:** This will return logs with "Invalid password" but *also* logs with "API key invalid" or "Successful password change". This is too broad.

**Lab 2: Phrase Search (Precise `and`)**
* **Action:** Select the `access-logs*` index pattern.
* **Task:** Search for the *exact phrase* "Invalid password".
* **KQL:** `message: "Invalid password"` (with quotes)
* **Result:** This now *only* returns logs with that specific error message.

**Lab 3: Combining Text and Field (The "error 404" example)**
* **Action:** Select the `access-logs*` index pattern.
* **Task:** Find all logs that had a `404` error *and* contained the word "File".
* **KQL:** `http.response.status_code: 404 and message: "File"`
* **Result:** A perfect, combined query. It uses a precise, fast, field-based search (`404`) and combines it with a full-text search (`File`). This is the "pro" workflow.