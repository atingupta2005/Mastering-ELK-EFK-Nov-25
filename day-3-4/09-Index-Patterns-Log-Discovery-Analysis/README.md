# Index Patterns

## 1. Purpose of Index Patterns

An index pattern is the most fundamental component for using Kibana. It is a saved object in Kibana that acts as a "bridge" or "connector" to one or more of your Elasticsearch indices.

You cannot use the Discover, Visualize, or Dashboard applications until you have at least one index pattern.

The index pattern serves two primary purposes:

1.  **To Define the "Data Source":** It tells Kibana *which* indices you want to search. An index pattern can point to a single, specific index (e.g., `orders-2020-01`) or, more commonly, use a wildcard (`*`) to match *multiple* indices (e.g., `access-logs*`).

2.  **To Define the "Schema":** It tells Kibana *what* your data looks like. When you create a pattern, Kibana reads the mappings of the matching indices. This is how it learns that:
    * `http.response.status_code` is a `long` (number).
    * `client.ip` is an `ip` address.
    * `@timestamp` is a `date`.
    * `message` is `text` (searchable).
    * `product.brand` is `keyword` (filterable and aggregatable).

Without this information, Kibana would not know how to build a date-range filter (it wouldn't know which field is the timestamp) or how to create a pie chart (it wouldn't know which fields are `keyword`s).

### Example: `access-logs*` vs. `orders*`

In a typical production environment, you have multiple, separate data streams. You must create a *separate* index pattern for each stream.

* **`access-logs*` Index Pattern:**
    * This pattern points to all your IT/operations log indices (`access-logs-2020-01`, `access-logs-2020-02`, etc.).
    * It tells Kibana about fields like `client.ip`, `http.response.status_code`, and `user_agent.original`.
* **`orders*` Index Pattern:**
    * This pattern points to all your business data indices (`orders-001`, `orders-002`, etc.).
    * It tells Kibana about fields like `product.price`, `customer.name`, and `total`.

When you are in the Discover app, you use the Index Pattern Selector (top-left) to switch between these two "views" of your data.

---

Here is the revised, exhaustive document for **"Time-based index patterns,"** complete with a practical hands-on lab as requested.

-----

## 2\. Time-based Index Patterns

### 1\. Conceptual Deep Dive

A time-based index pattern is the *most common and critical* data architecture in the Elastic Stack. Instead of storing all your data in one single, massive index (e.g., `my_logs`), you split the data into smaller, time-based indices.

This is done by adding a date to the index name. Common patterns are:

  * **Daily:** `access-logs-2025-11-13`, `access-logs-2025-11-14`
  * **Monthly:** `access-logs-2025-11`, `access-logs-2025-12`
  * **Yearly:** `access-logs-2025`, `access-logs-2026`

For example, your `access-logs` data is split monthly: `access-logs-2020-01`, `access-logs-2020-02`, and `access-logs-2020-03`.

#### Why is This Architecture Used?

This pattern is not just for organization; it is essential for performance and data management.

1.  **Search Performance:** A search over the last 24 hours is *infinitely* faster when Elasticsearch only has to search one small daily index (e.g., `access-logs-2025-11-13`) instead of a giant 50TB index containing 5 years of data. Elasticsearch can identify the time range of your search and *completely ignore* all other indices that don't match.

2.  **Data Retention (Lifecycle Management):** This is the most important reason. Companies have data retention policies (e.g., "delete all weblogs after 1 year").

      * **The Bad Way (One Big Index):** To delete old data, you would have to run a `DELETE_BY_QUERY` (e.g., "delete all documents where `@timestamp` is older than 1 year"). This is a resource-intensive, dangerous operation that can take hours and cripple your cluster.
      * **The Good Way (Time-based):** To delete data older than 1 year, you just run the `DELETE /access-logs-2024-11-13` command. This is an *instantaneous* operation.

#### How Kibana Handles This

This architecture creates a problem: how do you search all 12 monthly indices at once?

You *do not* want to create 12 different index patterns in Kibana. This is where the **wildcard (`*`)** becomes essential.

An index pattern in Kibana can use a wildcard to match multiple indices at once. By creating a *single* index pattern named **`access-logs*`**, you are telling Kibana to treat all of the following indices as *one single, giant, virtual index*:

  * `access-logs-2020-01`
  * `access-logs-2020-02`
  * `access-logs-2020-03`
  * ...and any future index that starts with `access-logs`.

When you search this `access-logs*` pattern in Kibana, it intelligently searches all matched indices. When you combine it with the Time Picker, it is even smarter: a search for "the last 7 days" will *only* be sent to the indices that could possibly contain that data (e.g., the current daily index), resulting in maximum speed.

-----

### 2\. Hands-On Lab: Proving the Power of Wildcard Patterns

This lab will demonstrate *why* a single wildcard pattern is superior to managing multiple, fixed-name patterns.

####  Lab 1: Setup - Create Two Time-Based Indices

First, we must create two separate, time-based indices to simulate a real environment.

  * **Action:** Navigate to **Management** -\> **Dev Tools**.
  * **Action:** Run the following two commands to create two empty indices, one for January and one for February.

<!-- end list -->

```http
PUT /practice-logs-2025-01
{
  "mappings": {
    "properties": {
      "@timestamp": { "type": "date" }
    }
  }
}
```

```http
PUT /practice-logs-2025-02
{
  "mappings": {
    "properties": {
      "@timestamp": { "type": "date" }
    }
  }
}
```

  * **Result:** You now have two distinct indices, `practice-logs-2025-01` and `practice-logs-2025-02`.

####  Lab 2: The "Wrong" Way (Fixed, Manual Patterns)

Let's see what happens if we don't use the wildcard.

1.  **Action:** Navigate to **Stack Management** -\> **Index Patterns**.
2.  Click **Create index pattern**.
3.  **Name:** `practice-logs-2025-01`.
4.  It will show "Success\! Your pattern matches 1 index." Click **Next step**.
5.  **Time field:** Select `@timestamp`. Click **Create index pattern**.
6.  **Action:** Go back to **Index Patterns** (click the link at the top).
7.  Click **Create index pattern** again.
8.  **Name:** `practice-logs-2025-02`.
9.  Create this pattern, again selecting `@timestamp`.

**Analyze the Problem:** You now have two separate index patterns. Go to **Discover**. In the top-left dropdown, you can see `practice-logs-2025-01` and `practice-logs-2025-02`. To search data for *both* January and February, you would have to run your query, switch patterns, and run the *exact same query* again. This is unmanageable.

####  Lab 3: The "Right" Way (Time-Based Wildcard Pattern)

1.  **Action: Clean Up:** Go back to **Stack Management** -\> **Index Patterns**.
2.  Click the checkbox next to `practice-logs-2025-01` and `practice-logs-2025-02`.
3.  Click the "Delete 2 index patterns" button.
4.  **Action: Create the Wildcard Pattern:**
5.  Click **Create index pattern**.
6.  **Name:** `practice-logs-*`
7.  **Analyze:** Look at the "Indices matching pattern" section. It will now say **"Success\! Your pattern matches 2 indices"** (`practice-logs-2025-01` and `practice-logs-2025-02`). This is the "A-ha\!" moment. The wildcard has matched both.
8.  Click **Next step**.
9.  **Time field:** Select `@timestamp`. Click **Create index pattern**.

**Analyze the Solution:** Go to **Discover**. You now have *one* index pattern, `practice-logs-*`. When you select this, you are searching *both* indices at the same time. If you were to add `practice-logs-2025-03` next month, this pattern would *automatically* include it without any new configuration.

####  Lab 4: Final Cleanup

1.  **Action:** Go to **Stack Management** -\> **Index Patterns** and delete the `practice-logs-*` pattern.
2.  **Action:** Go to **Dev Tools** and delete the practice indices.
    ```http
    DELETE /practice-logs-2025-01
    DELETE /practice-logs-2025-02
    ```
----

## 3. Creating Index Pattern in Kibana

### 1. Conceptual Deep Dive
An index pattern is the most fundamental component for using Kibana. It is a saved object in Kibana that acts as a "bridge" or "connector" to one or more of your Elasticsearch indices.

You **cannot** use the Discover, Visualize, or Dashboard applications until you have at least one index pattern.

The index pattern serves two primary purposes:

1.  **To Define the "Data Source":** It tells Kibana *which* indices you want to search. An index pattern can point to a single, specific index (e.g., `orders-2020-01`) or, more commonly, use a wildcard (`*`) to match *multiple* indices (e.g., `access-logs*`).

2.  **To Define the "Schema":** It tells Kibana *what* your data looks like. When you create a pattern, Kibana reads the mappings of the matching indices. This is how it learns that:
    * `http.response.status_code` is a `long` (number).
    * `client.ip` is an `ip` address.
    * `@timestamp` is a `date`.
    * `message` is `text` (searchable).
    * `product.brand` is `keyword` (filterable and aggregatable).

Without this information, Kibana would not know how to build a date-range filter (it wouldn't know which field is the timestamp) or how to create a pie chart (it wouldn't know which fields are `keyword`s).

### 2. Extensive Hands-On Lab: Creating Your Index Patterns

This lab will walk through the creation of two separate index patterns, one for `access-logs` and one for `orders`, to demonstrate how to manage different data sources.

**Prerequisite:** You must have already loaded your `access-logs` and `orders` data and index templates into Elasticsearch.

####  Lab 1: Creating the `access-logs*` Index Pattern

This pattern is designed to match all time-based `access-logs` indices, such as `access-logs-2020-01`, `access-logs-2020-02`, etc.

1.  **Navigate to Stack Management**
    * In Kibana, click the main navigation menu (☰) in the top-left corner.
    * Scroll to the bottom of the menu and click **Stack Management**.

2.  **Navigate to Index Patterns**
    * On the Stack Management page, find the "Kibana" section on the left.
    * Click **Index Patterns**.
    

3.  **Initiate Creation**
    * Click the **Create index pattern** button, located in the top-right corner.

4.  **Step 1: Define Pattern and Match Indices**
    * You are now on the "Create index pattern" screen.
    * In the text box under **Name**, type the pattern: `access-logs*`
    * As you type, Kibana will search your cluster for matching indices. A success message will appear below the box confirming the match (e.g., "Success! Your pattern matches 3 indices"). This verifies your data has been loaded and the pattern is correct.
    * Click **Next step**.

5.  **Step 2: Configure Time Field (Critical Step)**
    * Kibana needs to know which field in your data contains the primary timestamp. This is essential for enabling the Global Time Picker.
    * Click the **Time field** dropdown menu.
    * Select **`@timestamp`** from the list of available `date` fields.
    * Click **Create index pattern**.

**Verification:**
You will be redirected to the `access-logs*` schema page. This screen lists all 27 fields from your `access-logs` template, such as `client.ip`, `http.response.status_code`, and `user_agent.original`. You have successfully created your first index pattern.

####  Lab 2: Creating the `orders*` Index Pattern

This process demonstrates how to manage a second, completely separate data source.

1.  **Navigate to Index Patterns**
    * If you are still on the `access-logs*` schema page, click the "Index patterns" link in the breadcrumb navigation at the top of the page to go back.
    * Alternatively, go to **Stack Management** -> **Index Patterns**.

2.  **Initiate Creation**
    * Click **Create index pattern**.

3.  **Step 1: Define Pattern and Match Indices**
    * In the **Name** box, type the pattern: `orders*`
    * A success message will confirm that your pattern matches your `orders` indices.
    * Click **Next step**.

4.  **Step 2: Configure Time Field**
    * Click the **Time field** dropdown menu.
    * Select **`@timestamp`** (this field also exists in the `orders` schema).
    * Click **Create index pattern**.

**Verification:**
You will be redirected to the `orders*` schema page. This screen now lists all the *business* fields from your `orders` template, such as `product.price`, `customer.name`, and `total`.

####  Lab 3: Using the Index Pattern Selector
You have now successfully registered both of your data sources with Kibana.

1.  Navigate to **Discover** (☰ -> Analytics -> Discover).
2.  In the top-left corner, just below the "Discover" title, you will see a dropdown menu.
3.  Clicking this menu will now allow you to switch your "view" between **`access-logs*`** (to see IT data) and **`orders*`** (to see business data). This is the "switcher" that lets you move between your different datasets.

----

## 4\. Managing Multiple Patterns

### 1\. Conceptual Deep Dive

In any production environment, you will have more than one type of data. You will have your `access-logs*` for IT operations, your `orders*` for business analytics, `security-logs*` for security, `app-metrics*` for performance, and so on.

You *must* create a separate index pattern for each of these distinct data sources.

The **Index Patterns** management screen (in Stack Management) is your central hub for controlling all of these "connectors." From this one screen, you can View, Edit, Refresh, Delete, and set the Default pattern.

#### Key Management Tasks:

  * **Default Pattern:** One (and only one) index pattern can be set as the "default" (marked with a star icon). This is the pattern that Kibana will load *automatically* when you first open the Discover app.
  * **Refreshing Fields:** This is the most critical management task. Kibana *caches* the schema (the list of fields) from your index. If you modify your index template to add a new field (e.g., `http.request.tracking_id`), Kibana **will not see it** automatically. You must perform a "Refresh" to force Kibana to re-scan the mappings and find the new field.
  * **Deleting a Pattern:** This is a safe, non-destructive action. Deleting an index pattern **DOES NOT** delete any of your data in Elasticsearch. It only deletes the "connector" object *within* Kibana. You can always recreate it.

### 2\. Extensive Hands-On Lab: Managing Your Index Patterns

**Prerequisite:** You must have the `access-logs*` and `orders*` index patterns created from the previous lab.

####  Lab 1: Navigate and Set the Default Pattern

1.  **Action:** Navigate to **Stack Management** (☰ -\> Management -\> Stack Management).
2.  **Action:** Click **Index Patterns** (under Kibana).
3.  **Analyze:** You will see your list of patterns: `access-logs*` and `orders*`. One of them will have a **star icon** (★) next to it, marking it as the default.
4.  **Action:** Let's change the default. If `access-logs*` is the default, click the star icon next to `orders*`.
5.  **Analyze:** The star will move to `orders*`.
6.  **Test the Change:**
      * Navigate to **Discover** (☰ -\> Analytics -\> Discover).
      * **Result:** The page will load *automatically* with the `orders*` index pattern.
7.  **Action:** Go back to **Stack Management** -\> **Index Patterns** and set the default back to `access-logs*`.

####  Lab 2: Refreshing an Index Pattern (The "My new field is missing" problem)

This lab simulates a production scenario where a developer has added a new field to the logs.

1.  **The Scenario:** A developer has just added a `tracking_id` to the `access-logs`. We must add this to our mapping.

2.  **Action (Dev Tools):** Go to **Dev Tools**. We will add a new field to our *existing* index mapping. (Note: This is different from the template, as it applies to an index that already exists).

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

    *Result: You will get an `"acknowledged": true`. The `tracking_id` field is now known to Elasticsearch.*

3.  **Verify the Problem:**

      * **Action:** Go to **Discover** and select the `access-logs*` pattern.
      * **Action:** Look at the **Field List** on the left. Scroll or search for `http.request.tracking_id`.
      * **Result:** The field is **not there**. Kibana is still using its old, cached copy of the schema.

4.  **The Solution (Refresh):**

      * **Action:** Go to **Stack Management** -\> **Index Patterns**.
      * **Action:** Click on the `access-logs*` pattern name to open its schema viewer.
      * **Action:** In the top-right corner, click the **"Refresh"** button (a circular arrow icon).
      * **Action:** Kibana will ask you to confirm. Click **Refresh**.
      * **Result:** A pop-up will notify you: "Refreshed 1 field". You will now see `http.request.tracking_id` at the bottom of your field list.

5.  **Final Verification:**

      * **Action:** Go back to **Discover**.
      * **Action:** Look at the **Field List** on the left.
      * **Result:** The `http.request.tracking_id` field is now visible and ready for use in queries.

####  Lab 3: Safely Deleting an Index Pattern

This lab will prove that deleting a pattern is non-destructive.

1.  **Create a Dummy Index:**

      * **Action:** Go to **Dev Tools** and run: `PUT /cleanup-test-001`
      * *Result: The `cleanup-test-001` index now exists.*

2.  **Create a Dummy Pattern:**

      * **Action:** Go to **Stack Management** -\> **Index Patterns** -\> **Create index pattern**.
      * **Name:** `cleanup-test-*`
      * **Action:** Click **Next step**.
      * **Action:** Click "I don't want to use a time filter" (since this index has no `@timestamp`).
      * **Action:** Click **Create index pattern**.
      * *Result: The `cleanup-test-*` pattern now exists.*

3.  **Delete the Pattern:**

      * **Action:** Go back to the **Index Patterns** list page.
      * **Action:** Find `cleanup-test-*`. Click the checkbox to its left.
      * **Action:** Click the **"Delete index pattern"** button that appears at the top of the list.
      * **Action:** Type `delete` in the confirmation box and click **Delete**.
      * *Result: The `cleanup-test-*` index pattern is **gone**.*

4.  **Verify the Data is Safe:**

      * **Action:** Go back to **Dev Tools**.
      * **Action:** Run: `GET /_cat/indices?v`
      * **Result:** The `cleanup-test-001` index **is still there**. You have only deleted the Kibana "connector," not the data itself.

5.  **Final Cleanup:**

      * **Action:** In **Dev Tools**, run: `DELETE /cleanup-test-001`

----

## 5\. Common Mistakes with Patterns

### 1\. Conceptual Deep Dive

Creating an index pattern is the first and most critical step in using Kibana. While the process is simple, a small mistake can lead to a lot of confusion, typically resulting in the dreaded **"No results found"** message in Discover.

This guide will cover the three most common mistakes, how to diagnose them, and how to fix them.

1.  **The Time Field Mistake:** Forgetting to select a Time field or choosing the wrong one.
2.  **The Wildcard Mistake:** Forgetting the wildcard (`*`) and creating a pattern for a single, fixed index.
3.  **The Typo / Mismatch Mistake:** The pattern name does not actually match any indices.

Understanding these pitfalls is key to becoming a proficient Kibana administrator.

-----

### 2\. Extensive Hands-On Lab: The Time Field Mistake

**The Problem:** You create an index pattern but do not select a `@timestamp` field.
**The Symptom:** The Global Time Picker in Discover and on your dashboards will be disabled or will not work, forcing you to write all time-range queries manually.

####  Lab 1: Simulating the "No Time Field" Mistake

1.  **Action (Setup):** Go to **Dev Tools** and create a simple test index.

    ```http
    PUT /time-test-index
    {
      "mappings": {
        "properties": {
          "my_date": { "type": "date" },
          "message": { "type": "keyword" }
        }
      }
    }
    ```

2.  **Action (The Mistake):** Go to **Stack Management** -\> **Index Patterns** -\> **Create index pattern**.

3.  **Name:** `time-test-*`

4.  It will match your index. Click **Next step**.

5.  On the "Configure settings" screen, **do not select a time field**.

6.  Click the link at the bottom that says **"I don't want to use a time filter"**.

7.  Click **Create index pattern**.

8.  **Action (Verify the Problem):** Go to **Discover**.

9.  Select your new `time-test-*` index pattern from the dropdown.

10. **Analyze the Result:** Look at the top-right corner. The Time Picker is **gone**. It has been replaced with a message: **"This index pattern does not contain a time field."**

11. **Conclusion:** You have successfully created the pattern, but it is "crippled." You cannot filter by time, and the histogram is missing.

####  Lab 2: Fixing the "No Time Field" Mistake

You *cannot* add a time field to an existing pattern. You must delete and recreate it.

1.  **Action:** Go to **Stack Management** -\> **Index Patterns**.
2.  Find `time-test-*`, click the checkbox, and **Delete** it.
3.  **Action (The Fix):** Click **Create index pattern** again.
4.  **Name:** `time-test-*`
5.  Click **Next step**.
6.  **This time,** on the "Configure settings" screen, select `my_date` from the **Time field** dropdown.
7.  Click **Create index pattern**.
8.  **Action (Verify the Fix):** Go back to **Discover** and select the `time-test-*` pattern.
9.  **Result:** The Global Time Picker is now present and active. The histogram is visible. You have fixed the problem.

-----

### 3\. Extensive Hands-On Lab: The Wildcard (`*`) Mistake

**The Problem:** You have time-based indices (e.g., `access-logs-2020-01`, `access-logs-2020-02`) but you create a pattern for *only one* of them.
**The Symptom:** Your dashboards and Discover searches will mysteriously "lose" data. You'll search for data from February, but Kibana will show "No results found" because it's *only* configured to look at the January index.

####  Lab 3: Simulating the "Missing Wildcard" Mistake

1.  **Action (The Mistake):** Go to **Stack Management** -\> **Index Patterns** -\> **Create index pattern**.
2.  **Name:** `access-logs-2020-01` (Type the *full, exact* name of *one* of your indices. Do **NOT** use a wildcard).
3.  It will show "Success\! Your pattern matches 1 index." Click **Next step**.
4.  **Time field:** Select `@timestamp`. Click **Create index pattern**.
5.  **Action (Verify the Problem):** Go to **Discover**.
6.  Select your new `access-logs-2020-01` pattern.
7.  Set your **Time Picker** to `January 1, 2020` to `January 31, 2020`.
8.  **Result:** This works\! You will see all the data from January.
9.  **Action (The Failure):** Now, change the **Time Picker** to `February 1, 2020` to `February 28, 2020`.
10. **Analyze the Result:** **"No results found."** Even though your `access-logs-2020-02` index *exists* and has data, your pattern is *not looking at it*. You have "siloed" yourself to only the January data.

####  Lab 4: Fixing the "Missing Wildcard" Mistake

You must delete the bad pattern and create the correct one.

1.  **Action:** Go to **Stack Management** -\> **Index Patterns** and **Delete** the `access-logs-2020-01` pattern.
2.  **Action (The Fix):** Click **Create index pattern**.
3.  **Name:** `access-logs*` (This time, use the wildcard).
4.  **Analyze:** It will now show "Success\! Your pattern matches 3 indices" (or however many you have). It has found Jan, Feb, and Mar.
5.  Click **Next step**.
6.  **Time field:** Select `@timestamp`. Click **Create index pattern**.
7.  **Action (Verify the Fix):** Go back to **Discover**.
8.  Select the `access-logs*` pattern.
9.  Set the Time Picker to `February 1, 2020` to `February 28, 2020`.
10. **Result:** You will now see all the data from February. You have fixed the problem.

-----

### 4\. Extensive Hands-On Lab: The Typo / Mismatch Mistake

**The Problem:** You try to create a pattern, but Kibana can't find any matching indices.
**The Symptom:** The "Create index pattern" screen shows "No matching indices found."

####  Lab 5: Simulating the "Typo" Mistake

1.  **Action (The Mistake):** Go to **Stack Management** -\> **Index Patterns** -\> **Create index pattern**.

2.  **Name:** `acess-logs*` (Note the typo: only one 'c').

3.  **Analyze the Result:** The screen will immediately show a warning: **"No matching indices found."**

4.  **The Cause:** Your pattern `acess-logs*` does not match any index names in Elasticsearch.

5.  **The Fix:** Correct the typo in the text box to `access-logs*`. The error will disappear, and the "Success\!" message will appear.

####  Lab 6: Simulating the "Data Not Loaded" Mistake

This is the single most common "mistake" for first-time users.

1.  **The Scenario:** You have a new data source, `security-logs`, that you want to add. You go to Kibana to create the pattern *before* you have loaded any data.
2.  **Action (The Mistake):** Go to **Stack Management** -\> **Index Patterns** -\> **Create index pattern**.
3.  **Name:** `security-logs-*`
4.  **Analyze the Result:** **"No matching indices found."**
5.  **The Cause:** This is not a typo. The pattern is correct, but the data does not *exist* yet. Kibana cannot create a "connector" (an index pattern) to an index that does not exist.
6.  **The Fix (The Workflow):** The correct workflow is *always*:
    1.  Load your index template (e.g., `PUT /_index_template/security-logs`).
    2.  Load *at least one* index (e.g., `PUT /security-logs-000001` or load bulk data).
    3.  *Then*, go to Kibana to create the `security-logs-*` index pattern.

----