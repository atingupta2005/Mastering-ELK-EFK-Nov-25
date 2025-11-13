## 📅 Day 3: Load Sample Data (Weblogs)

### 1\. Conceptual Deep Dive: What is "Sample Data"?

We manually loaded data using the `_bulk` API. This is a common, *professional* way to load data, but it's technical.

Kibana, as a platform, wants to make it *easy* for new users to learn. To do this, Elastic provides a "Sample Data" feature.

**What is it?**
"Sample Data" is a **one-click installer** for a complete, pre-built dataset. When you add a "Sample Data" pack (like the "Sample web logs"), Kibana does *all* the work for you. In the background, it:

1.  **Creates** a new index (e.g., `kibana_sample_data_logs`).
2.  **Loads** thousands of realistic-looking, pre-made documents (log lines) into that index.
3.  **Creates** an Index Pattern (e.g., `kibana_sample_data_logs`) and links it to the `@timestamp` field.
4.  **Creates** pre-built Visualizations (charts, graphs, maps) for this data.
5.  **Creates** a pre-built Dashboard (e.g., `[Logs] Web Traffic`) that assembles all those visualizations.

**Why use it?**

  * **To Learn:** It's the absolute *fastest* way (30 seconds) to get data into Kibana to start clicking and exploring.
  * **To See the "Goal":** It shows you what a high-quality, finished dashboard *should* look like.
  * **To Test:** Before you build a complex visualization for your *own* data, you can test it on the sample data first.

**How is this different from *our* `access-logs` data?**

  * **Sample Data (Easy Mode):** A "demo" dataset. It's fantastic for learning, but it's not *your* data.
  * **Your `access-logs` (Pro Mode):** This is *your* custom, production data. You defined the schema, you control the data, and you must build your *own* dashboards from scratch.

In this lab, we will load the "Sample web logs" to see what a "finished" product looks like. We will then compare its fields to your `access-logs` schema to see how similar they are.

-----

### 2\. Extensive Hands-On Lab: Installing the "Sample Web Logs"

#### 🚀 Lab 1: Navigate to the Sample Data Directory

1.  In Kibana, navigate to the **Home** page (click the Elastic logo or the Kibana icon in the top-left corner).
2.  On the Home page, you will see a large "Welcome" message. Look for a section or button labeled **"Add integrations"** or **"Add sample data"**.
3.  Click it. You will be taken to the "Add data" / "Integrations" page.
4.  Find the link/button that says **"Sample data"**. Click it.
5.  You will now see a page with several "Sample data" cards, such as "Sample eCommerce orders," "Sample flight data," and "Sample web logs."

#### 🚀 Lab 2: Install the "Sample web logs"

1.  Find the card titled **"Sample web logs"**.
2.  On this card, click the **"Add"** button.
3.  The button will change to a loading spinner and say "Adding..."
4.  Wait about 30-60 seconds.
5.  When it is finished, the button will change to **"View data"**.
6.  **Congratulations.** You have just installed the entire dataset and all its related assets.

-----

### 3\. Conceptual & Hands-On Deep Dive: What Did We Just Install?

This single click did a *lot* of work. Let's verify what just happened.

#### 🚀 Lab 3: Verify the New Index

1.  Go to **Dev Tools** (☰ -\> Management -\> Dev Tools).
2.  Run this command to see all your indices:
    ```http
    GET /_cat/indices?v
    ```
3.  **Analyze the Result:** In the list of indices, you will now see:
      * Your `access-logs` indices (e.g., `access-logs-2020-01`).
      * A *new* index called `kibana_sample_data_logs`.
      * This confirms Kibana created a new index and loaded data into it.

#### 🚀 Lab 4: Verify the New Index Pattern

1.  Go to **Stack Management** (☰ -\> Management -\> Stack Management).
2.  Click **Index Patterns** (under Kibana).
3.  **Analyze the Result:** You will now see *two* index patterns:
      * `access-logs*` (the one you made for your data).
      * `kibana_sample_data_logs` (the new one that was just created automatically).

#### 🚀 Lab 5: Explore the New Data in Discover

1.  Go to **Discover** (☰ -\> Analytics -\> Discover).
2.  In the top-left corner, click the **Index Pattern selector** dropdown.
3.  Select **`kibana_sample_data_logs`**.
4.  **CRITICAL:** This sample data is from a few years ago. You *must* change the Time Picker.
5.  Click the **Time Picker** (top-right) and select **"Last 5 years"**.
6.  **Result:** You will now see thousands of log entries, complete with a histogram.
7.  **Explore the Fields:** Look at the **Field List** on the left.
      * This sample data has `agent`, `clientip`, `geo.coordinates`, `response.code`, `url`.
      * Compare this to your `access-logs` schema. They are *very* similar\!
      * `clientip` (sample) is your `client.ip` (yours).
      * `response.code` (sample) is your `http.response.status_code` (yours).
      * `geo.coordinates` (sample) is your `client.geo.location` (yours).
      * This shows that your custom `access-logs` schema is a professional, production-ready version of this common log type.

#### 🚀 Lab 6: View the Pre-Built Dashboard (The "Goal")

This is the most important part. Let's see the "finished product" that Kibana built for us.

1.  Go to **Dashboard** (☰ -\> Analytics -\> Dashboard).
2.  In the dashboard search bar, type **`[Logs] Web Traffic`**.
3.  Click on the dashboard name to open it.
4.  **Analyze the Result:**
      * You are now looking at a beautiful, fully interactive dashboard.
      * It has a **Global Map** showing `geo.coordinates`.
      * It has pie charts for `response.code`.
      * It has bar charts for `user_agent.name`.
      * It has a **Saved Search** panel at the bottom showing the raw logs.
      * **This is the "goal."** This is what you will learn to build *manually* using your *own* `access-logs` data.

-----

## 📅 Create an Index (The Professional Way)

### 1\. Conceptual Deep Dive: Why Create an Index Manually?

In the previous lab (Topic 30), we saw the "easy way" to create an index: by adding "Sample Data." Kibana did all the work *for* us. This is great for a demo, but it's not how a real system works.

In a professional environment, **you** (the administrator) must have *total control* over your data.

**Why create an index manually?**

  * **To Control Performance:** You must define the `number_of_shards` and `number_of_replicas`.
  * **To Control Storage:** You must define your data types. If you let Elasticsearch *guess*, it might map a status code (`"404"`) as `text`, which is 10x larger and slower than `keyword` or `long`.
  * **To Enforce Your Schema:** You need to *reject* bad data. If a developer's script suddenly adds a field called `"MISTAKE"`, you don't want that junk in your index.

#### Method 1: Direct Creation (The "Good" Way)

You can create a single, specific index using a `PUT` command. This is like building one custom house.
`PUT /my-single-index-001`

#### Method 2: Index Template (The "Professional" Way)

This is the *most important* method for production. You don't create an *index*; you create a **"blueprint"** called an **Index Template**.

  * An **Index Template** is *not* an index. It's a set of rules (`settings` and `mappings`).
  * This "blueprint" waits. When a *new* index is created that matches its `index_patterns` (e.g., `orders-*`), it *automatically* applies its rules to that new index.
  * This is the "blueprint" method. You design one perfect "blueprint" (`orders` template), and every "house" ( `orders-2020-01`, `orders-2020-02`, etc.) is built *perfectly* from that plan, every single time.

We will now use **Method 2** and install the **`orders`** template

-----

### 2\. Hands-On Lab: The "Wrong" Way (Dynamic Mapping)

Before we see the "right" way, we *must* see the "wrong" way to understand the risks. The "wrong" way is to let Elasticsearch *guess* your schema. This is called **Dynamic Mapping**.

#### 🚀 Lab 1: Create a "Dynamic" Index

1.  Navigate to **Dev Tools** (☰ -\> Management -\> Dev Tools).
2.  Run this simple command to create an empty index:
    ```http
    PUT /test-dynamic-index
    ```
    **Result:** You'll get an `"acknowledged": true`.

#### 🚀 Lab 2: Index a "Guesswork" Document

1.  Now, let's index a document. We haven't told Elasticsearch *any* rules, so it will have to guess.
    ```http
    POST /test-dynamic-index/_doc/1
    {
      "order_id": "123-abc",
      "status_code": "404",
      "total": "50.99",
      "message": "User failed to check out"
    }
    ```
    **Result:** It works\! The document is created.

#### 🚀 Lab 3: See the "Bad" Schema

1.  Now, let's see what schema Elasticsearch *guessed* for us.
    ```http
    GET /test-dynamic-index/_mapping
    ```
2.  **Analyze the Response (The "Problem"):** Look at the `properties` section. You will see something like this:
    ```json
    {
      ...
      "properties": {
        "order_id": { "type": "text", "fields": { "keyword": { ... } } },
        "status_code": { "type": "text", "fields": { "keyword": { ... } } },
        "total": { "type": "text", "fields": { "keyword": { ... } } },
        "message": { "type": "text", "fields": { "keyword": { ... } } }
      }
    }
    ```
3.  **This is a disaster\!**
      * `status_code` is `text`\! We can't do math on it (`status_code > 400`). We can't aggregate it properly.
      * `total` is `text`\! We *sent* it as a string (`"50.99"`), so Elasticsearch guessed it was `text`. We can *never* calculate our total sales.
      * `order_id` is `text`\! This is inefficient. It should be `keyword`.
4.  **Conclusion:** Never let Elasticsearch guess your schema.

#### 🚀 Lab 4: Clean Up

1.  Run this command to delete our bad test index.
    ```http
    DELETE /test-dynamic-index
    ```

-----

### 3\. Extensive Hands-On Lab: The "Professional" Way (Index Template)

Now, we will use the **`orders`** index template to build a "blueprint" for all our `orders*` indices.

#### 🚀 Lab 5: Create the `orders` Index Template

1.  **Action:** In **Dev Tools**, copy and paste the *entire* command.
    ```http
    PUT /_index_template/orders
    {
      "index_patterns": ["orders*"],
      "template": {
        "settings": {
          "index.mapping.coerce": false
        },
        "mappings": {
          "dynamic": false,
          "properties": {
            "@timestamp": { "type": "date" },
            "id": { "type": "keyword" },
            "product": {
              "properties": {
                "id": { "type": "keyword" },
                "name": { "type": "keyword" },
                "price": { "type": "float" },
                "brand": { "type": "keyword" },
                "category": { "type": "keyword" }
              }
            },
            "customer.id": { "type": "keyword" },
            "customer.age": { "type": "short" },
            "customer.gender": { "type": "keyword" },
            "customer.name": { "type": "keyword" },
            "customer.email": { "type": "keyword" },
            "channel": { "type": "keyword" },
            "store": { "type": "keyword" },
            "salesman.id": { "type": "keyword" },
            "salesman.name": { "type": "keyword" },
            "discount": { "type": "float" },
            "total": { "type": "float" }
          }
        }
      }
    }
    ```
2.  Run the command.
    **Result:** You will get `"acknowledged": true`. You have now loaded the "blueprint" into Elasticsearch's memory.

-----

### 4\. Conceptual Deep Dive: What Did We Just Do?

We just created a powerful, professional "blueprint." Let's break down the 3 most important parts of that template.

1.  `"index_patterns": ["orders*"]`

      * This tells the template to "watch" for any new index whose name *starts with* `orders`.
      * `orders-2020-01` -\> **Matches\!**
      * `orders-prod` -\> **Matches\!**
      * `access-logs-001` -\> **Does NOT match.**

2.  `"index.mapping.coerce": false`

      * This is an **advanced setting** in your template and is excellent.
      * "Coerce" means "force" or "guess." We have turned this **OFF**.
      * **What it does:** It makes Elasticsearch *strict*.
      * **Example:** Your mapping says `total` is a `float` (a number). If you try to index a document with `"total": "50.99"` (a string), this setting will cause Elasticsearch to **REJECT** the document.
      * **Why is this good?** It protects your data integrity. It stops "bad" data (like strings) from getting into your "clean" number fields.

3.  `"dynamic": false`

      * This is another **advanced, professional setting** in your template.
      * "Dynamic" refers to dynamic mapping (what we saw in Lab 2). We have turned this **OFF**.
      * **What it does:** It *locks* your schema.
      * **Example:** Your template defines 15 fields. If a developer's script tries to index a document and adds a *new*, *unknown* 16th field (e.g., `"notes": "test"`), Elasticsearch will **REJECT** the document.
      * **Why is this good?** It enforces your schema and prevents "schema drift," where your index gets polluted with hundreds of junk fields.

-----

### 5\. Hands-On Lab: Verifying the Template

This is the "A-ha\!" moment. We've loaded the blueprint, but *no index exists yet*. Let's prove the template works.

#### 🚀 Lab 6: Verify the Template Exists

1.  **Action:** Run this command to *read* the template you just created.
    ```http
    GET /_index_template/orders
    ```
    **Result:** You will see your template's configuration.

#### 🚀 Lab 7: Trigger the Template by Creating a Matching Index

1.  **Action:** Let's create a *brand new, empty index* whose name *matches* our pattern.
    ```http
    PUT /orders-lab-test-001
    ```
2.  **Result:** You'll get `"acknowledged": true`.

#### 🚀 Lab 8: Verify the Mappings were Applied

1.  **Action:** Now, let's ask Kibana for the schema of the new index we just created.
    ```http
    GET /orders-lab-test-001/_mapping
    ```
2.  **Analyze the Result:** Look at the `properties` section. You will see the *entire, complex schema* from your `orders` template\!
    ```json
    {
      "orders-lab-test-001": {
        "mappings": {
          "dynamic": "false",
          "properties": {
            "@timestamp": { "type": "date" },
            "id": { "type": "keyword" },
            "product": { ... },
            "customer.age": { "type": "short" },
            ...
            "total": { "type": "float" }
          }
        }
      }
    }
    ```
3.  **Conclusion:** This proves the "blueprint" worked. We created an empty index, but because its name (`orders-lab-test-001`) matched the template's pattern (`orders*`), Elasticsearch *automatically* applied all the correct settings and mappings.

#### 🚀 Lab 9: (Optional) Prove Schema Enforcement

1.  Now, let's prove that `"dynamic": false` works.
2.  **Action:** Try to index a document with a *new field* that's not in the template.
    ```http
    POST /orders-lab-test-001/_doc/1
    {
      "@timestamp": "2025-11-13T12:00:00Z",
      "id": "abc-123",
      "total": 50.0,
      "a_brand_new_field": "this will fail" 
    }
    ```
3.  **Result:** You will get a `400 Bad Request` error. The error type will be `strict_dynamic_mapping_exception`. This is **GOOD\!** The template has protected your index from being polluted with an unknown field.

#### 🚀 Lab 10: Clean Up

1.  **Action:** Let's delete our test index and the template.
    ```http
    DELETE /orders-lab-test-001
    DELETE /_index_template/orders
    ```

-----

## Try Filtering Documents in Kibana (Recap Lab)

### 1\. Conceptual Deep Dive: The Analyst's Workflow

Filtering is not just about finding a log; it's about **answering a question**.

A professional analyst's workflow looks like this:

1.  **The Question:** A manager asks, "Why did our site crash at 2:30 PM?"
2.  **The Hypothesis:** "I bet it was a spike in server errors (`5xx`) from our `payment-service`."
3.  **The Filter:** You go to Discover and build a filter:
      * **KQL:** `service_name: "payment-service" and http.response.status_code: 5*`
      * **Time Picker:** You set the time to 2:25 PM - 2:35 PM.
4.  **The Analysis:** The document table shows 5,000 logs, all with the message `NullPointerException`.
5.  **The Answer:** You've found the root cause.

This lab will put you in the role of the analyst. We will use *both* your `access-logs` and `orders` datasets to answer complex questions.

**Your Tools (A Quick Recap):**

  * **Time Picker:** Your master filter. **Always check this first.**
  * **KQL Bar:** Your "command line" for complex logic (`and`, `or`, `not`), text search, and ranges (`> 500`).
  * **Filter Pills:** Your "point-and-click" filters. Best for simple, exact `is` / `is not` conditions.

-----

### 2\. Extensive Hands-On Lab: Setup for a Two-Index Environment

This lab requires *two* index patterns. We already created `access-logs*`. Now, we must create one for your `orders` data.

**Prerequisites:**

1.  You have loaded your `access-logs` bulk data.
2.  You have loaded your `orders.bulk.ndjson` data.
3.  You have the `access-logs` index template loaded.
4.  You have the `orders` index template loaded (from the previous lab).

#### 🚀 Lab 1: Create the `orders*` Index Pattern

1.  Navigate to **Stack Management** (☰ -\> Management -\> Stack Management).
2.  Click **Index Patterns**.
3.  Click **Create index pattern**.
4.  **Step 1: Define pattern**
      * **Name:** `orders*`
      * Kibana will find your `orders` indices and show "Success\! Your pattern matches 1 index" (or however many you loaded).
      * Click **Next step**.
5.  **Step 2: Configure settings**
      * **Time field:** Select **`@timestamp`**.
      * Click **Create index pattern**.

**Setup Complete\!** You now have *two* index patterns: `access-logs*` and `orders*`. You can switch between them in the Discover app to search for either IT data or business data.

-----

### 3\. Extensive Hands-On Lab: Filtering `access-logs` (IT Operator Scenarios)

**Action:** Go to **Discover** (☰ -\> Analytics -\> Discover).

  * Select the **`access-logs*`** index pattern.
  * Set your **Time Picker** to your 2020 data (e.g., `Jan 1, 2020` to `Apr 1, 2020`).

#### 🚀 Scenario A: Security Audit

  * **The Question:** "I need a list of all potential breaches. Show me every `401` (Unauthorized) and `403` (Forbidden) log. But... ignore the `system` user; that's just our health check bot and it's noisy."

  * **Your Tools:** KQL `or`, `and`, `not`.

  * **Action (KQL Bar):**

    ```kql
    (http.response.status_code: 401 or http.response.status_code: 403) and not user_id: "system"
    ```

  * **Analyze the Result:** You will get a precise list of *actual* unauthorized requests (e.g., `recap-002`, `recap-010`, `recap-020`). You have successfully found all security issues while filtering out the "noise" from the system bot.

#### 🚀 Scenario B: Performance Debugging

  * **The Question:** "Our `/api/` endpoints feel slow. Find all `POST` requests to *any* API path that took longer than 1 second (1000ms)."

  * **Your Tools:** KQL `and`, wildcards (`*`), and range operators (`>`).

  * **Action (KQL Bar):**

    ```kql
    http.request.method: POST and url.path: /api/* and response_time_ms > 1000
    ```

  * **Analyze the Result:** This will find `recap-003` (the `payment-service` crash at 10500ms) and `recap-008` (the successful payment at 1200ms). This query is a perfect "slow API" detector.

#### 🚀 Scenario C: Geo-IP & User-Agent Analysis

  * **The Question:** "Our marketing team is running a campaign in China. Are they using the correct link? Find all traffic from 'China' that resulted in a `404 Not Found`."

  * **Your Tools:** KQL `and`.

  * **Action (KQL Bar):**

    ```kql
    client.geo.country_name: "China" and http.response.status_code: 404
    ```

  * **Result:** This will return any `404` logs from China, showing *exactly* which `url.path` is broken for that campaign.

#### 🚀 Scenario D: Advanced Filtering (KQL + Filter Pills)

  * **The Question:** "This is complex. I need to find all `500` errors from the `frontend-web` service. Once I have that list, I want to *also* filter it to see which ones were *only* from `Firefox` users."

  * **Your Tools:** KQL for the base search, then a Filter Pill for the drill-down.

  * **Action (Step 1: KQL):**

    ```kql
    http.response.status_code: 500 and service_name: "frontend-web"
    ```

    (Press Enter. You now have a list of all `500` errors on the frontend.)

  * **Action (Step 2: Filter Pill):**

    1.  Look at the **Field List** on the left.
    2.  Find and click `user_agent.name`.
    3.  Hover over `Firefox` and click the **`+` (Filter for value)** icon.

  * **Analyze the Result:** You now have:

      * **KQL:** `http.response.status_code: 500 and service_name: "frontend-web"`
      * **Filter Pill:** `user_agent.name is "Firefox"`
      * The document table is now filtered for *both* conditions. This is the "drill-down" workflow in action.

-----

### 4\. Extensive Hands-On Lab: Filtering `orders` (Business Analyst Scenarios)

**Action:** Go to **Discover** (☰ -\> Analytics -\> Discover).

  * Change the **Index Pattern** (top-left) to **`orders*`**.
  * Set your **Time Picker** to `Jan 1, 2020` to `Apr 1, 2020` (or whenever your `orders` data is from).

*(Note: Since I don't have your `orders.bulk.ndjson` data, I will write queries based on your `orders` schema. You may need to adjust values like "Brenda Nguyen" or "Electronics" to match your actual data.)*

#### 🚀 Scenario E: Sales Performance Review

  * **The Question:** "We need to review the high-value sales from our top salesman, 'Brenda Nguyen'. Find all sales for her that were over $100."

  * **Your Tools:** KQL `and`, range (`>`).

  * **Action (KQL Bar):**

    ```kql
    salesman.name: "Brenda Nguyen" and total > 100
    ```

  * **Analyze the Result:** You'll get a list of all high-value orders for that specific salesperson, ready to be exported for a commission report.

#### 🚀 Scenario F: Marketing Demographics

  * **The Question:** "Our new 'Active Life' (brand) campaign is targeted at men aged 25-35. Is it working? Find all sales for this brand to this demographic."

  * **Your Tools:** KQL `and`, range (`>=`, `<=`).

  * **Action (KQL Bar):**

    ```kql
    product.brand: "Active Life" and customer.gender: "male" and customer.age >= 25 and customer.age <= 35
    ```

  * **Analyze the Result:** This gives you a precise list of every "on-target" sale, proving the campaign's effectiveness.

#### 🚀 Scenario G: Advanced Business Logic (KQL + Filter Pills)

  * **The Question:** "I need to find all 'Electronics' sales. After I see that list, I want to quickly toggle between 'Online' (channel) and 'In-Store' (channel) sales."

  * **Your Tools:** KWL for the base, Filter Pills for the "toggle."

  * **Action (Step 1: KQL):**

    ```kql
    product.category: "Electronics"
    ```

    (Press Enter. You now have *all* Electronics sales.)

  * **Action (Step 2: Filter Pills):**

    1.  In the Field List, find and click `channel`.
    2.  Hover `Online` and click the **`+`** icon.
    3.  **Analyze:** You see all Electronics sales from the `Online` channel.
    4.  **Action:** Now, click the **"Invert"** button (magnifying glass) on the `channel is "Online"` pill.
    5.  **Analyze:** The pill instantly flips to `channel is not "Online"`. Your list updates to show all *other* sales (e.g., "In-Store"). You can toggle this back and forth for instant comparison.

-----

## Export Search Results to CSV

### 1\. Conceptual Deep Dive: Why Export Data? (The "Last Mile")

You have now mastered finding and filtering your data *inside* Kibana. But Kibana is an *analyst's* tool. Your manager, your security team, or your VP of Sales probably does not want to log in and write KQL queries.

They just want a **report**.

"Exporting" is the "last mile" of your analysis. It's the process of getting your valuable, filtered data *out* of Elasticsearch and into a format that a human can use in a meeting or in an email.

The most common and useful format for this is **CSV (Comma-Separated Values)**, because it can be opened by any spreadsheet program, like Microsoft Excel, Google Sheets, or Apple Numbers.

#### How Kibana Reporting Works (A Critical Concept)

This is the \#1 "gotcha" for new users. Clicking "Generate CSV" does **not** instantly download a file.

**Why?** Imagine you searched for "all logs from 2020." That could be 50 million log lines, which might be a 10GB file. Your browser *cannot* handle that.

Instead, Kibana uses a **background task** workflow:

1.  **You (The Analyst):** You build the perfect view in Discover (KQL, filters, time range, custom columns).
2.  **You click "Generate CSV".**
3.  **Kibana (Background):** A "report job" is created. Kibana *re-runs your exact query* on the server, in the background. It doesn't matter if you close your browser.
4.  **Kibana (Background):** It builds the *entire* CSV file (even if it's 10 million lines) and saves it temporarily on the Kibana server.
5.  **Kibana (UI):** It sends you a small notification: "Report is ready."
6.  **You (The Analyst):** You must navigate to the **Reporting** management page to download the finished file.

-----

### 2\. Extensive Hands-On Lab: Exporting `access-logs` (A Security Report)

**Scenario:** A security manager, who doesn't have Kibana access, needs a full report of all unauthorized (`401`) and forbidden (`403`) access attempts from our `access-logs` data for Q1 2020.

#### 🚀 Lab 1: Build the "Security Report" View

**This is the most important step.** The CSV export will *only* contain the data you filter for, and it will *only* have the columns you make visible. You must build a clean view *first*.

1.  Navigate to **Discover** (☰ -\> Analytics -\> Discover).
2.  Select your **`access-logs*`** index pattern.
3.  Set your **Time Picker** to your 2020 data (e.g., `Jan 1, 2020` to `Apr 1, 2020`).
4.  **Build the Query:** In the KQL bar, type:
    ```kql
    http.response.status_code: 401 or http.response.status_code: 403
    ```
5.  Press Enter. The list will update to show only `401` and `403` logs.
6.  **Customize the Columns (CRITICAL):**
      * The default `message` column is messy. We need a clean report.
      * In the **Field List** on the left, find and **add** (`+`) the following fields:
          * `@timestamp`
          * `client.ip`
          * `user_id`
          * `http.request.method`
          * `url.path`
          * `http.response.status_code`
      * Now, find `message` in the "Selected fields" list at the top of the sidebar and **remove** (`-`) it.
7.  **Review:** You now have a clean, 6-column table showing *only* the security failures. This is a perfect "report view."

#### 🚀 Lab 2: Generate the CSV Report

1.  In the Discover toolbar (at the top of the page, above the histogram), find the **Reporting** button.
2.  Click **Reporting**.
3.  A small menu will open. Click **"Generate CSV"**.
4.  A pop-up will appear. You can leave the "Include formatted fields" toggle **ON**.
5.  Click the **"Generate"** button.
6.  A "Creating report..." pop-up will appear in the bottom-right. It will tell you: "You can track its progress in **Management / Reporting**."

#### 🚀 Lab 3: Download the Finished Report

1.  Now, we go to the "download" page.
2.  Navigate to **Stack Management** (☰ -\> Management -\> Stack Management).
3.  Under the "Kibana" heading, find and click **Alerts and Reports** -\> **Reporting**.
4.  You will see a list of all your generated reports. The one you just created will be at the top, and its "Status" will say **Completed**.
5.  On the far right of that row, click the **Download** icon (a downward-facing arrow).
6.  Your browser will now download the CSV file (e.g., `access-logs.csv`).

#### 🚀 Lab 4: Verify the CSV

1.  Open the downloaded `.csv` file in Microsoft Excel, Google Sheets, or any text editor.
2.  **Verify the Columns:** You will see that the headers are *exactly* the 6 columns you selected: `@timestamp`, `client.ip`, `user_id`, etc.
3.  **Verify the Data:** You will see that the rows *only* contain logs with `401` or `403` in the `http.response.status_code` column.
4.  **Success\!** You have successfully exported a clean, filtered report for your manager.

-----

### 3\. Extensive Hands-On Lab: Exporting `orders` (A Business Report)

Let's do it again, but for a business scenario.

**Scenario:** The VP of Sales wants a CSV of all sales over $100 from the "Online" channel, for the "Active Life" brand.

*(Note: Adjust these values like "Active Life" or "Online" to match your actual `orders` data.)*

#### 🚀 Lab 5: Build the "Sales Report" View

1.  Navigate to **Discover**.
2.  Change your **Index Pattern** (top-left) to **`orders*`**.
3.  Set your **Time Picker** to your 2020 data.
4.  **Build the Query (KQL):**
    ```kql
    total > 100 and channel: "Online" and product.brand: "Active Life"
    ```
5.  **Customize the Columns:**
      * **Add (`+`):**
          * `@timestamp`
          * `id` (the order ID)
          * `customer.name`
          * `product.name`
          * `product.price`
          * `discount`
          * `total`
      * **Remove (`-`):** `message` (if it's there).
6.  **Review:** You now have a perfect, 7-column table of high-value online sales.

#### 🚀 Lab 6: Generate and Download the CSV

1.  Click **Reporting** -\> **Generate CSV**.
2.  Click **Generate**.
3.  Wait for the notification.
4.  Go to **Stack Management** -\> **Reporting**.
5.  You will see your new report (e.g., `orders.csv`) at the top of the list.
6.  Click the **Download** icon.
7.  **Success\!** You now have a CSV file ready for the VP of Sales.

-----

### 4\. Conceptual & Hands-On Deep Dive: Other Sharing Options

A CSV is for *offline* users. What if you want to share your *Kibana view* with another *Kibana user*?

#### 🚀 Lab 7: Sharing a "Permalink" (A Link to Your View)

1.  Go back to **Discover** and load your "Security Report" view from Lab 1 (`http.response.status_code: 401 or 403`).
2.  In the Discover toolbar, click the **Share** button (next to Reporting).
3.  A "Share" pop-up will appear. You have several options:
      * **Permalink:** This is the one you want.
      * **Short URL:** This generates a *very long* URL that contains your *entire query and time range*.
      * **Snapshot:** (Default) This is the best option. It's a "snapshot" of your current view.
4.  Click **"Copy link"**.
5.  **Test it:** Open a new, incognito browser window (or send the link to a teammate).
6.  When they open the link and log in, they will see **exactly what you see**:
      * The `access-logs*` index pattern.
      * The KQL query `http.response.status_code: 401 or 403`.
      * The *exact* Time Picker range (e.g., Jan 1 - Apr 1 2020).
      * Your *exact* custom columns.
7.  **Conclusion:** A **Permalink** is for sharing your *live, interactive view* with other Kibana users. A **CSV Export** is for sharing your *static data* with non-Kibana users.

-----

## Troubleshoot Common Query & Data Errors

### 1\. Conceptual Deep Dive: The Analyst's Troubleshooting Mindset

This lab covers the most common *real-world* problems you will face. These are not server-down errors; these are the much more common "Why doesn't my data look right?" or "Why did my query fail?" errors.

Your primary tool for this is not the Linux command line, but the **Discover** tab, **Dev Tools**, and your understanding of **Mappings**.

We will cover the Top 4 most common analytical errors and how to solve them.

-----

### 2\. The \#1 Problem: "No results found\!" (Your 4-Step Checklist)

This is the most common issue. You run a search, and the screen says **"No results found."** 99% of the time, the data is there, but your *view* is wrong.

Always check these 4 things, in this exact order.

#### ✅ 1. Check the Time Picker (The 90% Culprit)

  * **The Problem:** You are searching for your 2020 `access-logs` data, but your Time Picker (top-right) is set to **"Last 15 minutes."**
  * **The Fix:** This is almost always the answer. Click the Time Picker and set an **Absolute** range that *includes* your data (e.g., `Jan 1, 2020` to `Apr 1, 2020`).

#### ✅ 2. Check the Index Pattern (The 5% Culprit)

  * **The Problem:** You are in Discover, and you are trying to find an order with `product.category: "Electronics"`. You see "No results found." You check the Time Picker, and it's correct.
  * **The Cause:** You forgot to switch your Index Pattern. Look in the top-left corner. Your active Index Pattern is still **`access-logs*`**. The `orders` data does not exist in the `access-logs` index.
  * **The Fix:** Click the dropdown and switch your Index Pattern to **`orders*`**. The data will now appear.

#### ✅ 3. Check Your Filter Pills (The 3% Culprit)

  * **The Problem:** You are searching for `http.response.status_code: 500`. You see "No results found." You check your Time Picker and Index Pattern, and both are correct.
  * **The Cause:** You forgot about a **Filter Pill** you added 30 minutes ago. Under your KQL bar, you have a pill: `http.response.status_code is 200`. A log cannot be *both* `500` AND `200` at the same time.
  * **The Fix:** Look under the KQL bar. Click the `x` on any old filters that are conflicting with your new query.

#### ✅ 4. Check Your KQL Query (The 2% Culprit)

  * **The Problem:** You are *sure* all of the above are correct.
  * **The Cause:** You have a subtle typo in your query.
  * **Example:** You search `client.geo.country_name: "USA"`. No results. You check the Field List, and you see the *actual* value is `"United States"`. Your query was correct, but your *data* was different.
  * **The Fix:** Always use the **Field List** on the left to see the *actual* "Top 5 values." This helps you avoid guessing.

-----

### 3\. The "Coercion" Problem: My Number Query Fails

This is a specific, advanced problem caused by templates.

  * **The Concept:** Templates include `"index.mapping.coerce": false`. This makes your index *strict*. A `long` (number) field will *only* accept numbers. A `string` (text/keyword) field will *only* accept strings.
  * **The Symptom:** You run a query in **Dev Tools** that *looks* right, but it fails.
  * **Action (Dev Tools):**
    ```http
    POST /access-logs-2020-01/_search
    {
      "query": {
        "term": {
          "http.response.status_code": "404"  <-- The error is here
        }
      }
    }
    ```
  * **The Error:** The query fails with a `query_shard_exception`. The `reason` will be:
    `"failed to create query: ... failed to parse 'http.response.status_code' as number. ... "coerce" set to false, therefore falling back to parsing as string"`
  * **The Cause:** Your query is *lying* to Elasticsearch. You are sending `"404"` (a string) but the mapping for `http.response.status_code` is `long` (a number). Because `coerce` is `false`, Elasticsearch *refuses* to guess.
  * **The Fix:** Send the correct data type.
    ```http
    POST /access-logs-2020-01/_search
    {
      "query": {
        "term": {
          "http.response.status_code": 404  <-- Correct (no quotes)
        }
      }
    }
    ```
  * **Kibana Note:** The KQL bar in **Discover** (`http.response.status_code: 404`) is smart about this. It knows the field is a number and will send the correct query for you. This error mostly happens in **Dev Tools**.

-----

### 4\. The "Text vs. Keyword" Problem: My Filter Fails

This is the most common *analytical* error.

  * **The Symptom:** You are *positive* you have logs with "Failed" in the message. You run a query in Dev Tools... and get **0 results**.
  * **Your (Broken) Query (Dev Tools):**
    ```http
    POST /access-logs-2020-01/_search
    {
      "query": {
        "term": {
          "message": "Failed" 
        }
      }
    }
    ```
  * **The Cause:** You are using a `term` query on a `text` field.
      * A `term` query looks for **one exact token**.
      * The `message` field is `text`. It was *analyzed*.
      * The string `"Failed login attempt"` was broken into tokens: `[failed]`, `[login]`, `[attempt]`. (All lowercase).
      * Your `term` query searched for the *exact token* `"Failed"` (uppercase F). This token *does not exist* in the inverted index.
  * **The Fix (Solution 1):** Use a `match` query, which *is* analyzed.
    ```http
    POST /access-logs-2020-01/_search
    {
      "query": {
        "match": {
          "message": "Failed" 
        }
      }
    }
    ```
    (This works, because "Failed" is analyzed into `[failed]`, which matches the index).
  * **The Fix (Solution 2):** Use the `keyword` sub-field (if you have one). Your `access-logs` template *does not* have one for `message`, but your `url.original` does\!
      * `url.original` is `keyword`.
      * `url.original.text` is `text`.
      * **Query:** `POST /_search { "query": { "term": { "url.original": "/api/v1/login" } } }` -\> **Works\!**
      * **Query:** `POST /_search { "query": { "term": { "url.original.text": "/api/v1/login" } } }` -\> **Fails (0 results)\!**

**Rule of Thumb:**

  * Use `match` on `text` fields.
  * Use `term` on `keyword` fields.

-----

### 5\. The "Aggregations Failed" Problem (The `fielddata` Error)

This is a classic, advanced error.

  * **The Symptom:** You are in Dev Tools. You want to see the "Top 5 most common log messages." You run an aggregation.

  * **Your (Broken) Query (Dev Tools):**

    ```http
    GET /access-logs-2020-01/_search
    {
      "size": 0,
      "aggs": {
        "top_messages": {
          "terms": {
            "field": "message" 
          }
        }
      }
    }
    ```

  * **The Error:** The query fails with a long, angry error that says:
    `"Aggregations on 'text' fields are disabled by default. Set 'fielddata=true' on 'message' to enable them..."`

  * **The Cause:** You are trying to *aggregate* (group by) a `text` field.

      * Elasticsearch *hates* this. It's memory-intensive and slow.
      * A `text` field (`message`) is optimized for *searching* (e.g., `match: "failed"`).
      * A `keyword` field (`http.request.method`) is optimized for *aggregating* (e.g., `terms: { "field": "http.request.method" }`).

  * **The Fix (Solution 1 - The "Wrong" Fix):** You *could* run `PUT /access-logs-2020-01/_mapping { "properties": { "message": { "type": "text", "fielddata": true } } }`. **NEVER DO THIS.** This will use huge amounts of memory and can crash your cluster.

  * **The Fix (Solution 2 - The "Right" Fix):** Your `access-logs` template *already solved this* for other fields. Look at its mapping for `url.original`:

    ```json
    "url.original": {
      "type": "keyword",
      "fields": {
        "text": {
          "type": "text",
          "norms": false
        }
      }
    }
    ```

    This is called a **multi-field**. It indexes the *same data* twice:

    1.  `url.original`: as a `keyword` (for aggregating/sorting)
    2.  `url.original.text`: as `text` (for full-text search)

    Your template *should* have done this for `message`. Since it didn't, the *only* correct fix is to **re-index your data** with a corrected template that maps `message` as both `text` and `keyword`.

  * **How to Fix Your "Top Messages" Query:** You can't. You *cannot* aggregate on the `message` field as it is currently mapped. You *can*, however, aggregate on `url.original`:

    ```http
    GET /access-logs-2020-01/_search
    {
      "size": 0,
      "aggs": {
        "top_urls": {
          "terms": {
            "field": "url.original"  <-- This works, because it's a keyword!
          }
        }
      }
    }
    ```

-----
