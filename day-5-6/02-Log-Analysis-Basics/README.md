## 📅 Day 5: Log Analysis Basics

This module provides a set of practical "recipes" for answering common analytical questions. You will use the Discover tab to move beyond simple searching and start performing real-world analysis on your `access-logs` and `orders` data.

**Prerequisite:**

  * You are in the **Discover** application (☰ -\> Analytics -\> Discover).
  * Your **Time Picker** is set to an absolute range that includes all your sample data (e.g., `January 1, 2020` to `April 1, 2020`).

-----

### 1\. Spotting Spikes in Errors

#### Conceptual Overview

Log analysis often begins by identifying anomalies in data volume. A "spike" is a sudden, significant increase in the count of a specific type of log, which typically indicates a meaningful event such- as a service failure, a security event, or a misconfiguration.

The primary tool for this analysis is the **Discover Histogram**. This bar chart displays the count of documents (y-axis) over your selected time range (x-axis).

This histogram is not static; it dynamically redraws itself to reflect the results of your KQL query and filters. By default, it shows the count of *all* logs. By applying a query (e.g., `http.response.status_code: 401`), you change the histogram to show the count of *only* `401` error logs. This allows you to visually pinpoint the exact time an error spike occurred.

#### 🚀 Hands-On Lab: Visual Analysis of a Security Spike

**Prerequisite:**

  * Navigate to **Discover**.
  * Select the `access-logs*` index pattern.
  * Set your **Time Picker** to the absolute range of your 2020 sample data.

**Lab 1.1: Isolate a Security Spike (`401` Errors)**

1.  **Task:** An analyst suspects a brute-force login attempt. We need to find the timeline of "Unauthorized" errors.
2.  **Action:** In the KQL search bar, enter the following query:
    `http.response.status_code: 401`
3.  **Analyze:** Observe the **Histogram**. It will update to show *only* the `401` errors. If these errors all occur in one or two bars, you have found a "spike," which is a strong indicator of an attack.

**Lab 1.2: Correlate Spikes for Root Cause Analysis**

1.  **Task:** The `401` spike is interesting, but we also want to see if it's related to `404` errors (which could be an attacker "probing" for admin panels).
2.  **Action:** Modify your KQL query to show *both* error types:
    `(http.response.status_code: 401 or http.response.status_code: 404)`
3.  **Analyze:** The histogram will now show the combined timeline of both `401` and `404` errors. This gives you a more complete picture of the potential attack.

**Lab 1.3: Zoom in on a Spike for Context**

1.  **Task:** Now that we've seen the spike, we need to see what *else* was happening at that exact moment.
2.  **Action:** In the KQL bar, **clear your query** and press Enter. The histogram will update to show *all* log traffic again.
3.  **Action:** On the histogram, find the time of the `401` spike you just identified.
4.  **Action:** Click and drag your mouse to select a small window *around* that spike (e.g., a 10-minute range).
5.  **Analyze:** The **Time Picker** and **Document Table** update to this new, small time range. You can now see the full sequence of *all* logs (not just errors) that led up to and followed the security event. This "neighbor analysis" is essential for debugging.

-----

### 2\. Tracking Top IP Addresses

#### Conceptual Overview

A common question is "Who is hitting my server?" or "Which client is causing all these errors?" The **Field List** on the left side of Discover automatically calculates the "Top 5" values for `keyword` fields, which is the perfect tool for this.

This feature is dynamic. It shows the Top 5 values for *all data in your current view*. If you filter for `500` errors, the Top 5 list will *also* update to show you the Top 5 IPs responsible *only* for those `500` errors.

#### 🚀 Hands-On Lab: Finding Top N Values

**Lab 2.1: Find "Top Browsers" (Overall Traffic)**

1.  **Action:** Select the `access-logs*` index pattern. Clear all KQL queries and filters.
2.  **Action:** In the **Field List** (left sidebar), find and click the `user_agent.name` field.
3.  **Analyze:** The field will expand to show the **Top 5** browser names (e.g., `Chrome`, `Firefox`, `curl`) and the percentage of all logs they are responsible for.

**Lab 2.2: Find "Top Referrers" (Marketing Analysis)**

1.  **Task:** We want to know which external websites are sending us the most traffic.
2.  **Action (KQL):** We must first filter *out* any logs that don't have a referrer. In the search bar, type `http.request.referrer: *` and press Enter. (This finds all logs where the referrer field "exists").
3.  **Action:** Now, in the Field List, find and click `http.request.referrer`.
4.  **Analyze:** The Top 5 list now shows the *exact* domains that are sending you the most traffic.

**Lab 2.3: Find "Top Customers" (Business Analysis)**

1.  **Action:** Switch your **Index Pattern** (top-left) to `orders*`.
2.  **Action:** Clear all KQL queries and filters.
3.  **Action:** In the **Field List**, find and click `customer.name`.
4.  **Analyze:** The field expands to show your **Top 5** customers by *number of orders placed*.

-----

### 3\. Checking User Activity

#### Conceptual Overview

This is the "needle in a haystack" workflow. A specific user (e.g., `user_id: "admin"`) reports a problem, or you see them in a log and want to know *everything* they did. This is a filtering exercise.

By filtering for a single `user_id`, `customer.name`, or `client.ip`, you can isolate their activity and see their session from beginning to end, sorted by time.

#### 🚀 Hands-On Lab: Tracing a User Session

**Lab 3.1: Trace a User in `access-logs`**

1.  **Action:** Select the `access-logs*` index pattern. Clear all KQL and filters.
2.  **Task:** Find all activity for `user_id: "admin"`.
3.  **Action (Filter):** In the **Field List**, find and click `user_id`.
4.  Hover over `admin` (or another user) and click the **`+` (Filter for value)** icon.
5.  **Analyze:** A filter pill `user_id is "admin"` is added. The document table now shows *only* logs from this user, sorted by time. You can read their `url.path` actions like a story, creating a complete audit trail of their session.

**Lab 3.2: Correlate User Activity with Errors**

1.  **Task:** Now that we are watching the `admin` user, we *only* want to see the errors they encountered.
2.  **Action:** *Keep* the `user_id is "admin"` filter pill.
3.  **Action (KQL):** In the search bar, type `not http.response.status_code: 200`.
4.  **Analyze:** The document table updates. It now shows all logs that are:
      * (Filter) `user_id is "admin"`
      * **AND**
      * (KQL) `http.response.status_code` is *not* `200`.
        You have a complete list of all `404`, `500`, `401`, etc., errors for *only* that user.

**Lab 3.3: Trace an Order ID in `orders`**

1.  **Action:** Switch your **Index Pattern** to `orders*`.
2.  **Task:** A customer calls about `order_id` "xyz-123" (find a real ID from your data).
3.  **Action (KQL):** In the search bar, type `id: "xyz-123"`.
4.  **Analyze:** The table shows the single order. You can expand it to see all details: the customer, the products, the price, and the `salesman.name`.

-----

### 4\. Identifying Slow Response Times

#### Conceptual Overview

Site performance is a critical metric. Your `access-logs` schema contains the `response_time_ms` field, which is a `long` (number). We can analyze this field to find bottlenecks.

#### 🚀 Hands-On Lab: Finding Slow Requests

**Lab 4.1: Find All Slow Requests (Simple Range Query)**

1.  **Action:** Select the `access-logs*` index pattern.
2.  **Task:** Find all requests that took longer than 1.5 seconds (1500 milliseconds).
3.  **Action (KQL):** In the search bar, type `response_time_ms > 1500` and press Enter.
4.  **Analyze:** The document table instantly filters to show *only* your slowest requests.

**Lab 4.2: Find the "Top 10 Slowest" Requests (Sorting)**

1.  **Action:** Clear the KQL bar.
2.  **Task:** We want to see a "Top 10 Slowest" list, regardless of time.
3.  **Action (Customize Table):** In the Field List, add the `response_time_ms` field as a column to your document table (click the `+` button).
4.  **Action (Sort):** Click the **header** of the `response_time_ms` column in the table. It will sort ascending (fastest). Click the header **again**.
5.  **Analyze:** The table is now sorted *descending* (slowest to fastest). The very first log in the list is the single slowest request in your entire time range.

**Lab 4.3: Get Average Response Time for a *Specific URL***

1.  **Task:** What is the *average* response time for our `/api/v1/login` endpoint?
2.  **Action (KQL):** In the search bar, type `url.path: "/api/v1/login"`.
3.  **Action:** In the **Field List** (left), find and click `response_time_ms`.
4.  **Analyze:** The field expands to show you statistics for the logs *that match your query*. You will see:
      * **`min`:** The fastest login
      * **`max`:** The slowest login
      * **`avg`:** The average login time
        This is a powerful, instant statistical view that updates with every query.

-----

### 5\. Adding Scripted Field (Basic Calculation)

#### Conceptual Overview

Sometimes, your data is not in the perfect format. Your `orders` data has `product.price` and `discount`, but you really want to know the *final sale price*.

A **Scripted Field** is a *virtual* field that you create *inside Kibana*. It does **not** change your original data. It runs a calculation on-the-fly at query time. It uses a language called **Painless**.

#### 🚀 Hands-On Lab: Create a "Sale Price" Field

**Lab 5.1: Create the Scripted Field**

1.  **Action:** Navigate to **Stack Management** (☰ -\> Management -\> Stack Management).

2.  **Action:** Click **Index Patterns** (under Kibana).

3.  **Action:** Click the `orders*` pattern name to open its settings.

4.  **Action:** Click the **"Scripted fields"** tab (next to the "Fields" tab).

5.  **Action:** Click **"Add scripted field"** (or "Create scripted field").

6.  **Action:** Fill out the form:

      * **Name:** `sale_price`
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
    // This is safer than just `return doc['product.price'].value - doc['discount'].value`
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

      * *Note:* If you get a "script compilation error," double-check for typos.

**Lab 5.2: Use Your New Scripted Field**

1.  **Action:** Navigate back to **Discover** (You may need to refresh the page).
2.  **Action:** Select the **`orders*`** index pattern.
3.  **Action:** In the **Field List** on the left, you will now see your *new* virtual field: `sale_price`, with a `#` icon.
4.  **Action (Use in Table):**
      * Add `product.price` to your document table.
      * Add `discount` to your document table.
      * Add `sale_price` to your document table.
      * **Analyze:** You can now see the original price, the discount, and your new calculated sale price, all side-by-side.
5.  **Action (Use in KQL):**
      * You can now *query* this virtual field.
      * **KQL:** `sale_price < 10`
      * **Analyze:** The query works. You have successfully found all "bargain" orders where the *final* price was less than $10, using a field that doesn't physically exist in your index.