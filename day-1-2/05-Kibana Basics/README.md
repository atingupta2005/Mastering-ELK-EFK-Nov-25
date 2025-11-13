## 🖼️ Kibana Basics

In the previous section, we were in the "engine room" of Elasticsearch, using **Dev Tools** to send raw API commands. Now, we move to the "cockpit"—the Kibana User Interface (UI). This is the visual, point-and-click way to explore and visualize your data.

### 20\. Kibana UI Walkthrough

When you first log in to Kibana (version 9.x), you'll land on a **Home** page. This page is a "jumping-off point" that shows your recently viewed items and suggests ways to add and explore your data.

The entire UI is organized by the **main navigation menu**, which you can open by clicking the "hamburger" icon (☰) in the top-left corner.

This menu is organized into sections based on the *use cases* we discussed (Observability, Security, Search).

For this course, we will focus on two key areas:

1.  **Analytics:** This is the "classic" ELK section. It's where you find the tools to explore and visualize your log data.

      * **Discover**
      * **Dashboard**
      * **Visualize Library**

2.  **Management (Bottom of menu):** This is the "admin" section. It's where you configure Kibana and its connection to Elasticsearch.

      * **Dev Tools** (This is where we just were\!)
      * **Stack Management** (This is where we will go next, to create Index Patterns)

-----

### 21\. Discover, Dashboard, and Visualize Sections

The **Analytics** section is built on three core applications. It's helpful to think of them with an analogy, like building with LEGOs.

| Application | 🧱 LEGO Analogy | Purpose |
| :--- | :--- | :--- |
| **Discover** | **The Raw Bricks** | This is the "raw data" view. It's where you go to search, filter, and read individual log lines (documents). It's the `SELECT * ... WHERE ...` of Kibana. |
| **Visualize** | **A Single Creation** | This is the "chart builder." You use it to take a "search" and turn it into a single chart, graph, map, or metric. (e.g., a pie chart of `http_status` codes). |
| **Dashboard** | **The Final LEGO City** | This is the "story-telling" view. It's a collection of many different visualizations, all arranged on one screen to give you a high-level overview of your system. |

You will almost always follow this workflow:

1.  Go to **Discover** to explore your data and understand what you have.
2.  Go to **Visualize** to build charts based on your discoveries.
3.  Go to **Dashboard** to assemble your charts into a final report.

-----

### 22\. Creating Index Patterns in Kibana

**This is the most important first step in Kibana.**

Before you can use the **Discover** tab, you must tell Kibana *which* Elasticsearch index (or indices) you want to explore. An **Index Pattern** is a "saved search" that tells Kibana what data to look at.

**Why is it a "Pattern"?**
In production, you don't use one giant index (like our `web-logs`). You use time-based indices, like:

  * `web-logs-2025-11-09`
  * `web-logs-2025-11-10`
  * `web-logs-2025-11-11`

You don't want to create a new pattern every day\! So, you create one **Index Pattern** called `web-logs*` (using a wildcard `*`). This single pattern will automatically match all of those daily indices.

####  Hands-On Lab: Creating our Index Pattern

Let's create the pattern for the `web-logs` index we made in the last lab.

1.  Click the main menu (☰) in the top-left.
2.  Scroll *all the way down* to the **Management** section.
3.  Click **Stack Management**.
4.  On the left, under "Kibana," click **Index Patterns**.
5.  Click the **Create index pattern** button (top right).

**Step 1: Define the pattern**

  * In the "Name" box, type `web-logs`.
  * Kibana will search for indices that match. It will show you `1 matching source`.
  * Click **Next step**.

**Step 2: Configure settings**

  * Kibana needs to know which field contains your timestamp. This is *critical* for using the time picker.
  * From the **Time field** dropdown, select **`@timestamp`**.
  * Click **Create index pattern**.

**Success\!**
You will now see a table of all the fields in your `web-logs` index. Notice how Kibana already knows their data types (e.g., `client_ip` is an `ip`, `http_status` is a `keyword`, `message` is a `text`). It read the **mappings** we created in the last lab.

-----

### 23\. Searching in Discover Tab

Now that we have an index pattern, we can finally explore our data.

1.  Click the main menu (☰) and go to **Analytics** -\> **Discover**.
2.  In the top-left (under the "Discover" title), make sure your `web-logs` index pattern is selected.

You are now looking at the **Discover** interface. Let's break it down:

  * **1. Time Picker (Top Right):** This is the most powerful feature. It controls the time range for *all* your searches. The default is "Last 15 minutes."
      * **Action:** Click it and change it to **"Today"**. You should now see our 12 log entries.
  * **2. KQL Search Bar (Top):** This is where you write your queries. KQL (Kibana Query Language) is a simple, powerful search syntax.
  * **3. Field List (Left Sidebar):** A list of all fields in your index. You can click them to see the top values (e.g., click `http_status` to see `200`, `404`, `500`).
  * **4. Histogram (Top Chart):** A bar chart showing the *count* of documents over the time range you selected.
  * **5. Document Table (Bottom):** The "raw" list of your log messages. You can click the `>` arrow on any log to expand it and see all the JSON fields.

####  Hands-On Lab: Searching with KQL

KQL is simpler than the full Query DSL. Let's try the same searches we did in Dev Tools. Type these into the KQL bar and press Enter.

**Example 1: Simple text search (like Google)**
This will search all `text` fields (like our `message` field).

```kql
payment
```

  * **Result:** Shows the 2 documents (`log-003`, `log-006`) that mention "payment".

**Example 2: Search for an exact phrase**
Use double quotes `"` for phrases.

```kql
"File not found"
```

  * **Result:** Shows the 2 documents (`log-002`, `log-005`) with that exact message.

**Example 3: Field-based search (this is what you'll use most)**
This is the equivalent of our `term` query.

```kql
http_status: 404
```

  * **Result:** Shows the 2 "Not Found" errors.

**Example 4: Combining searches (AND)**

```kql
user_id: alice and http_status: 200
```

  * **Result:** Shows the 2 successful requests from 'alice' (`log-004`, `log-007`).

**Example 5: Combining searches (OR)**
Let's find all our critical errors.

```kql
http_status: 500 or http_status: 403
```

  * **Result:** Shows our 3 critical errors (`log-003`, `log-011`, `log-012`).

**Example 6: Using `not`**

```kql
user_id: bob and not http_status: 200
```

  * **Result:** Shows the 2 errors for 'bob' (the `500` payment error and the `403` forbidden error).

**Example 7: Range search**
Let's find all slow requests.

```kql
response_time_ms > 1000
```

  * **Result:** Shows the 2 requests that took over a second (`log-003`, `log-012`).

-----

### 24\. Filtering Logs in Discover

Writing KQL is great, but sometimes it's faster to just point and click. **Filters** are "queries" that you add to your search, which are shown as "pills" under the search bar.

You can add filters *without* writing any KQL.

####  Hands-On Lab: Adding Filters

**Method 1: The "Easy Way" (from the Document Table)**

1.  Clear your KQL bar (make it blank) and press Enter. You should see all 12 logs.
2.  Click the `>` arrow to expand `log-004` (a log from 'alice').
3.  You will see all the fields. Find the `user_id: "alice"` row.
4.  On the right, you will see two small icons: a **`+` (plus)** and a **`-` (minus)**.
      * Click the **`+` (Filter for value)** icon.
5.  **Look up\!** A new "pill" has appeared under the search bar: `user_id is "alice"`. Your document list *instantly* updates to show only the 3 logs from 'alice'.

**Method 2: The "Even Easier Way" (from the Field List)**

1.  Remove the filter you just added (click the `x` on the "pill").
2.  Look at the **Field List** on the left.
3.  Click on the `http_status` field to expand it.
4.  It will show you the "Top 5 values" for that field: `200` (6 hits), `404` (2 hits), `500` (2 hits), etc.
5.  Hover your mouse over the `500` row.
6.  Click the **`+` (Filter for value)** icon that appears.
7.  **Boom\!** A filter `http_status is "500"` is added, and your list now shows only the 2 `500` errors.

#### Combining Search and Filters

Now, let's combine everything.

1.  You should still have the `http_status is "500"` filter active.
2.  Go to the **KQL Search Bar** and type `payment`.
3.  Press Enter.

**Result:** You will get **1 document** (`log-003`). Your search has found all documents that match **both** the KQL query (`payment`) **AND** the filter (`http_status: 500`).

This combination of a KQL query + UI-based filters is the primary way you will find and debug issues in Kibana.