## 📅 Create Index Pattern for Weblogs

### 1. Conceptual Deep Dive: What is an Index Pattern?

Before you can visualize or even *see* a single piece of data in Kibana, you must create an **Index Pattern**. This is the single most important "first step" of using Kibana.

**What is it?**
An Index Pattern is **not** your data. It is a "bridge" or a "connector" that tells Kibana *how* to find and *how* to interpret your data.

Think of your Elasticsearch indices as thousands of books in a giant library, all locked in a dark room.
* **Indices (`access-logs-2020-01`, `access-logs-2020-02`):** These are the individual "books," full of data.
* **Index Pattern (`access-logs*`):** This is the **Card Catalog** and the **Master Key**. It tells Kibana:
    1.  **What to find (The Key):** "Go to the 'access-logs' section of the library." The wildcard (`*`) on the end tells it to unlock *all* books that start with `access-logs`.
    2.  **How to read it (The Catalog):** "In these books, `http.response.status_code` is a number, `client.ip` is an IP address, and `message` is searchable text."

Without this "Card Catalog," Kibana is blind. It doesn't know what data you have, what it's called, or how to search it.

#### Why is the "Pattern" (Wildcard `*`) so important?

Your `README.md` file shows you load data into time-based indices:
* `access-logs-2020-01`
* `access-logs-2020-02`
* `access-logs-2020-03`

This is a best practice called an "index rollover." You would *never* want to log in to Kibana every month to add the "February" index, then the "March" index.

By creating an index pattern with the name **`access-logs*`**, you are telling Kibana: "From now on, automatically find and include *any index, forever,* that starts with the words `access-logs`."

This single pattern will match all of them:
* `access-logs-2020-01` (Matches)
* `access-logs-2020-02` (Matches)
* `access-logs-2020-03` (Matches)
* `access-logs-2020-04` (Will match automatically when it's created)
* `orders-2020-01` (**Does not match** - which is what we want!)

#### Why is the "Time Field" so important?

During creation, Kibana will ask you to select a **Time field**. This is the *second* most critical step.

* You *must* select the **`@timestamp`** field from your schema.
* This selection links your index pattern to Kibana's **Global Time Picker** (the calendar in the top-right corner).
* If you *don't* select a time field, the time picker will be disabled. You won't be able to filter by "Last 15 minutes" or "Today." You would have to write complex `range` queries for *every search*. By selecting `@timestamp`, you enable all of Kibana's powerful time-based features.

---

### 2. Hands-On Lab: Creating the `access-logs*` Pattern

**Prerequisites:**
1.  Your `access-logs` index template has been loaded via Dev Tools.
2.  Your `access-logs-2020-01`, `...-02`, and `...-03` bulk data has been loaded.

#### 🚀 Lab 1: Navigating to Index Pattern Management

1.  In Kibana, click the main navigation menu (☰) in the top-left corner.
2.  Scroll *all the way down* to the **Management** section.
3.  Click **Stack Management**. 
4.  On the next screen, look on the left-hand side. Under the "Kibana" heading, click **Index Patterns**.
5.  You will see a screen that says "You have no index patterns." Let's fix that.

#### 🚀 Lab 2: Defining the Index Pattern


1.  Click the **Create index pattern** button (top-right).
2.  You are now on the "Create index pattern" screen.
3.  **Step 1: Define the pattern**
    * In the text box under "Name", type `access-logs*`
    * **STOP and LOOK.** As you type, Kibana is live-searching your Elasticsearch cluster.
    * A "success" message will appear below the box: **"Success! Your pattern matches 3 indices"** (or however many `access-logs` indices you loaded).
    * It will list the indices it found (e.g., `access-logs-2020-01`, `access-logs-2020-02`, etc.). This is your confirmation that the pattern is correct.
    * Click **Next step**.
4.  **Step 2: Configure settings**
    * This is the critical Time Field step.
    * Kibana will ask you to "Choose a time field...".
    * Click the dropdown menu. It will show you a list of all `date` fields in your schema.
    * Select **`@timestamp`**.
    * Leave "Show advanced settings" alone for now.
    * Click **Create index pattern**.

#### 🚀 Lab 3: Exploring the Index Pattern Schema

**Success!** You will not see a success message. Instead, you will be taken directly to the **`access-logs*` schema viewer page**. This page is your "Card Catalog" made manifest.

This is a *CRITICAL* screen that most beginners ignore. Let's explore it.



You will see a giant table of all **27 fields** from your `access-logs` template.

**Task 1: Filter the Fields**
* At the top, there is a "Filter fields" bar. This is essential when you have 500+ fields.
* **Action:** Type `geo` into the bar.
* **Result:** The list instantly filters to your 7 `client.geo.*` fields.
* **Action:** Type `http.response` into the bar.
* **Result:** The list filters to `http.response.body.bytes` and `http.response.status_code`.

**Task 2: Understand the "Type" Column**
* Clear the filter. Look at the "Type" column.
* Kibana *read* your index template's mappings. This is why:
    * `client.ip` is `ip`
    * `client.geo.location` is `geo_point`
    * `http.response.status_code` is `number` (from your `long` type)
    * `http.request.method` is `string` (from your `keyword` type)
    * `message` is `string` (from your `text` type)
* This "Type" tells Kibana what kind of UI to use (e.g., a map for `geo_point`, a number range for `number`).

**Task 3: Understand the "Badges" (Searchable vs. Aggregatable)**
* Look at the "Controls" column. You see badges for "Searchable" and "Aggregatable."
* **`message`:** Is **Searchable** but **NOT Aggregatable**.
    * **Why?** It's a `text` field. You can search *inside* it (e.g., `message: "error"`), but you can't *group* by it (you can't make a pie chart of all "messages").
* **`http.request.method`:** Is **Searchable** AND **Aggregatable**.
    * **Why?** It's a `keyword` field. You can search for it (`http.request.method: GET`) AND you can aggregate it (e.g., "Show me a pie chart of `GET` vs. `POST` vs. `PUT`").
* **This is the most important concept in all of ELK.** Your `access-logs` template is set up correctly: `keyword` fields are for *filtering and aggregating*; `text` fields are for *full-text search*.

---

### 3. Troubleshooting & Common Mistakes

**Mistake 1: "No matching indices found!"**

* **You type:** `access-logs*`
* **Kibana says:** "No matching indices found."
* **The Problem (99% of the time):** You haven't loaded any data yet! You **must** load data *first* (like your `nginx-access-logs-2020-01.bulk.ndjson`) *before* you can create a pattern for it.
* **Other Causes:**
    1.  **Typo:** You typed `acess-logs*` (missing a 'c').
    2.  **Wrong Time:** Your data is very old, and Kibana is only checking for "today's" indices. (This is rare, but possible).

**Mistake 2: "I forgot the wildcard!"**
* **You type:** `access-logs-2020-01` (you forgot the `*`).
* **It works!** You create the pattern.
* **The Problem:** You go to Discover and set the time for February 2020. **No data is found.** Your pattern *only* matches the January index.
* **The Fix:** Go to **Stack Management** -> **Index Patterns**. Click the `...` (ellipses) next to your broken pattern and **Delete** it. Re-create it correctly with `access-logs*`.

**Mistake 3: "My new field is missing!"**
* **The Scenario:** You just updated your application to add a *new* field to your logs: `http.request.body.bytes`.
* **The Problem:** You go to Kibana, but this field is *not* in your Field List.
* **The Fix:** Kibana *caches* the schema. You must tell it to refresh.
    1.  Go to **Stack Management** -> **Index Patterns**.
    2.  Click on your `access-logs*` pattern.
    3.  In the top-right corner, click the **"Refresh"** button (a circular arrow).
    4.  Kibana will re-scan your indices and find the new field.

---

## Search Sample Log Data (Discover)

### 1. Conceptual Deep Dive: The "Discover" Interface

In the previous section, we built the "bridge" to our data (the Index Pattern). Now, we will walk across that bridge into the **Discover** application.

**Navigate:** Click the main menu (☰) -> **Analytics** -> **Discover**.

This is your **"home base" for all log analysis**. It is the single most important screen for debugging and exploration. Think of it as a powerful, interactive "Search" page for your data.



The Discover UI is made of 5 key components:

1.  **The Index Pattern Selector (Top-Left):**
    * This dropdown menu lets you choose *which* "bridge" you want to use. You must select your **`access-logs*`** pattern here. If you had an `orders*` pattern, you could switch to it.

2.  **The Time Picker (Top-Right):**
    * **This is the most important filter on the entire screen.** It controls the time range for *everything* you see. If this is set to "Last 15 minutes," you will **never** find your 2020 data. You *must* set this to the time range of your data.

3.  **The KQL Search Bar (Top):**
    * This is your "command line." This is where you will type queries to search your data. The language it uses is **KQL (Kibana Query Language)**.

4.  **The Field List (Left Sidebar):**
    * This is your "menu of ingredients." It is a list of all 27 fields from your `access-logs` pattern. You can click these fields to add filters, see top values, and customize your view.

5.  **The Main Content Area (Center):**
    * **Histogram:** A bar chart showing the *volume* of logs over your selected time.
    * **Document Table:** A row-by-row list of the actual log documents that match your search.

### 2. Conceptual Deep Dive: KQL (Kibana Query Language)

KQL is the simple, powerful language you type in the search bar. It's designed to be easy to write, like a Google search.

#### Two Ways to Search

1.  **Free-Text Search (Simple, but "dumb"):**
    * **Query:** `error`
    * **What it does:** Kibana searches *all* fields marked as `text` in your schema. Based on your `access-logs` template, it will search:
        * `message`
        * `url.original.text`
        * `user_agent.original.text`
        * `user_agent.os.name.text`
        * `user_agent.os.full.text`
    * This is great for a "best guess" but can return a lot of noise.

2.  **Field-Based Search (Precise, Powerful, Professional):**
    * **Query:** `http.response.status_code: 500`
    * **What it does:** This is far more efficient. It *only* searches the `http.response.status_code` field for the value `500`.
    * **This is the primary way you will search 99% of the time.**

#### KQL Core Operators

| Operator | Purpose | Example |
| :--- | :--- | :--- |
| `and` | (Default) All terms must match. | `user_agent.name: "Chrome" and client.geo.country_name: "China"` |
| `or` | At least one term must match. | `http.response.status_code: 500 or http.response.status_code: 503` |
| `not` | Excludes documents with this term. | `http.response.status_code: 200 and not user_id: "system"` |
| `()` | Groups logic together. | `(http.response.status_code: 401 or 403) and http.request.method: POST` |
| `>` `<=` | Range operators for numbers/dates. | `http.response.body.bytes > 10000` |
| `*` | Exists operator (or wildcard). | `http.request.referrer: *` (finds all logs that *have* a referrer) |
| `""` | Phrase operator. | `message: "Invalid password"` (finds this exact phrase) |

---

### 3. Extensive Hands-On Lab: Searching the `access-logs` Data

This is the core of your Day 2 lab. We will run a series of "search drills" to find specific data in your `access-logs*` index.

#### 🚀 Prerequisite Step 0: Set the Stage!

1.  Navigate to **Discover** (☰ -> Analytics -> Discover).
2.  In the top-left, make sure your index pattern is set to **`access-logs*`**.
3.  In the top-right, click the **Time Picker**.
    * Click the **Absolute** tab.
    * Set **Start date** to `January 1, 2020 @ 00:00:00.000`
    * Set **End date** to `April 1, 2020 @ 00:00:00.000`
    * Click **Update**.
4.  You should now see a histogram and a long list of log documents. You are ready to search.

---

#### 🚀 Lab 1: Free-Text and Phrase Searches

**Objective:** To perform "Google-like" searches on your `text` fields.

* **Drill 1.1: Find a general term**
    * **Task:** You suspect there are "failed" events. Find all logs that mention "failed".
    * **KQL:** `failed`
    * **Result:** This will return logs from `message` with "Failed login attempt", "Failed API request", etc.

* **Drill 1.2: Find a specific phrase**
    * **Task:** The results for "failed" are too noisy. You *only* want to see "Invalid password" logs.
    * **KQL:** `"Invalid password"` (with double quotes)
    * **Result:** The list will now *only* show `access-logs` documents where the `message` field contains that exact phrase.

* **Drill 1.3: Find a value in a `text` field**
    * **Task:** Find all logs from a "Chrome" browser.
    * **KQL:** `Chrome`
    * **Result:** This will search all `text` fields. You'll see results, but this is a *bad* query. The *correct* way is in the next lab.

---

#### 🚀 Lab 2: Field-Based `keyword` Searches (The "Filter")

**Objective:** To perform precise, fast, and professional searches using your `keyword` fields.

* **Drill 2.1: Find all `POST` requests**
    * **Task:** Show me *only* the logs for `POST` requests.
    * **KQL:** `http.request.method: POST`
    * **Result:** A clean list of all documents where `http.request.method` is "POST".

* **Drill 2.2: Find all traffic from China**
    * **Task:** Isolate all logs originating from China.
    * **KQL:** `client.geo.country_name: "China"` (Use quotes because the name has a space).
    * **Result:** A list of all logs geolocated to China.

* **Drill 2.3: Find all scripted traffic from `curl`**
    * **Task:** We want to see requests from scripts, not browsers. Find all `curl` traffic.
    * **KQL:** `user_agent.name: "curl"`
    * **Result:** A list of all requests made using the `curl` user agent.

---

#### 🚀 Lab 3: Field-Based `numeric` Searches (Status & Size)

**Objective:** To use numeric fields to find errors and measure impact.

* **Drill 3.1: Find all `404 Not Found` errors**
    * **Task:** Find all broken links.
    * **KQL:** `http.response.status_code: 404`

    * **⭐ CRITICAL CONCEPT: `coerce: false`**
        * Your `access-logs` template includes `"index.mapping.coerce": false`. This is a strict setting.
        * It means if you search `http.response.status_code: "404"` (with quotes), the search will **FAIL** or return 0 results.
        * **Why?** The field type is `long` (a number), but you sent a `string` ("404"). `coerce: false` tells Elasticsearch **not** to convert the type.
        * **Rule:** Always search numbers as numbers!

* **Drill 3.2: Find all `5xx` Server Errors (Pro Tip)**
    * **Task:** Find all server-side errors (e.g., `500`, `503`, `502`).
    * **KQL:** `http.response.status_code: 5*`
    * **Result:** Using a wildcard `*` with a numeric field like this is a *KQL-only feature* that is extremely useful. It will find `500`, `503`, etc.

* **Drill 3.3: Find all "Large" requests**
    * **Task:** Find all requests that sent more than 10,000 bytes.
    * **KQL:** `http.response.body.bytes > 10000`
    * **Result:** A list of logs, sorted by time, of all large responses.

---

#### 🚀 Lab 4: Combined Searches (AND/OR/NOT/Grouping)

**Objective:** To solve real-world problems by combining queries.

* **Drill 4.1: (AND) Find all `404` errors for `GET` requests**
    * **Task:** A `404` on a `POST` might be fine, but on a `GET` it means a broken link. Find them.
    * **KQL:** `http.response.status_code: 404 and http.request.method: GET`
    * **Result:** A precise list of broken `GET` requests.

* **Drill 4.2: (OR) Find all *critical* server errors**
    * **Task:** Show me all `500` (Internal Server Error) *or* `503` (Service Unavailable) logs.
    * **KQL:** `http.response.status_code: 500 or http.response.status_code: 503`
    * **Result:** A combined list of all critical server failures.

* **Drill 4.3: (NOT) Find all `Chrome` traffic that was *not* successful**
    * **Task:** We want to find errors that `Chrome` users are experiencing.
    * **KQL:** `user_agent.name: "Chrome" and not http.response.status_code: 200`
    * **Result:** A list of all logs from Chrome that are `404`, `500`, `401`, etc.

* **Drill 4.4: (Grouping) Complex debugging**
    * **Task:** Find all `401` (Unauthorized) or `404` (Not Found) errors that came from a `Python` script.
    * **KQL:** `(http.response.status_code: 401 or http.response.status_code: 404) and user_agent.name: "Python"`
    * **Result:** A highly specific list, proving the power of grouping with `()`.

---

#### 🚀 Lab 5: Exists Searches

**Objective:** To find documents based on whether a field *has* a value or not.

* **Drill 5.1: Find all logs that have a referrer**
    * **Task:** We want to see all traffic that was "referred" to us from another site.
    * **KQL:** `http.request.referrer: *`
    * **Result:** A list of all logs where the `http.request.referrer` field is not empty.

* **Drill 5.2: Find all anonymous traffic**
    * **Task:** We want to find all logs that do *not* have a `user_id`.
    * **KQL:** `not user_id: *`
    * **Result:** A list of all logs where the `user_id` field is missing or empty.

---

#### 🚀 Lab 6: Exploring the Document Table

**Objective:** To customize your view to make the data more readable.

1.  **Run a search:** In the KQL bar, type `user_agent.name: "Chrome"` and press Enter.
2.  **Look at the Table:** The default columns are `Time` and `message`. This isn't very helpful. We can't see the status code or IP.
3.  **Customize the Table:**
    * Look at the **Field List** on the left.
    * Find `client.ip`. Hover over it and click the `+` button. The `client.ip` column is added to your table.
    * Do the same for these fields:
        * `http.request.method`
        * `url.path`
        * `http.response.status_code`
        * `http.response.body.bytes`
    * Now you have a table with 6 useful columns.
4.  **Remove the `message` column:**
    * In the **Field List**, find the `message` field (it will have a checkmark).
    * Hover over it and click the `-` (minus) button.
    * **Result:** You now have a clean, customized table showing only the data you care about.
5.  **Sort the Data:**
    * Click the header for the `http.response.body.bytes` column.
    * It will re-sort your view to show the smallest requests. Click it again to see the *largest* requests.

---

### 4. Troubleshooting & Common Mistakes

* **Problem 1: "No results found!"**
    * **Cause (99% of the time):** Your **Time Picker** is wrong.
    * **Fix:** Click the Time Picker. Make sure you are looking at 2020, not "Last 15 minutes."

* **Problem 2: "My search for `http.response.status_code: "404"` returns nothing!"**
    * **Cause:** Your template has `coerce: false`. This is a *good* thing, but it's strict. You are searching for a `string` ("404") in a `long` (number) field.
    * **Fix:** **Always search numbers as numbers.** Use `http.response.status_code: 404`.

* **Problem 3: "My search for `message: "File not found"` returns logs with "File" or "not" or "found", not the whole phrase."**
    * **Cause:** You did not use double quotes `""`. KQL's default for free-text search is `OR`. Your search was `message: File or not or found`.
    * **Fix:** Use double quotes for all exact phrase searches: `message: "File not found"`.

---

## 📅 Filter Logs (e.g., for Status = 404)

### 1. Conceptual Deep Dive: KQL Search vs. Kibana Filters

In the last section, we used the **KQL Search Bar**. This is just one of *two* ways to find your data. The second, and often more powerful, way is by using **Kibana Filters**.

Understanding the difference is the *single most important concept* for mastering Kibana.



| Feature | **KQL Search Bar (The "Finder")** | **Kibana Filters (The "Sieve")** |
| :--- | :--- | :--- |
| **Purpose** | To *find* data. Good for free-text, complex logic, and "fuzzy" searches. | To *sift* or *reduce* data. Good for exact, structured "yes/no" questions. |
| **How it works** | Analyzes your query, calculates a `_score` (relevancy) for `text` fields. | A "Yes/No" test. A document either matches the filter or it doesn't. No `_score`. |
| **Why?** | You want to find "failed login" in a message. | You want to *only* see data from `http.response.status_code: 404`. |
| **Analogy** | A Google search. | The "filter" checkboxes on an e-commerce site (e.g., "Brand: Sony", "Price: $100-$200"). |

**The "Power" Workflow (This is what professionals do):**
You almost *always* use both together. They are combined with a logical **`AND`**.

**`Final Results = (Your KQL Query) AND (Filter 1) AND (Filter 2) ...`**

* **Example:**
    * **KQL:** `payment` (Find all logs with the word "payment")
    * **Filter:** `http.response.status_code is 500`
    * **Result:** You see *only* the "payment" logs that *also* had a `500` error.

**Why are Filters (Pills) better for `status = 404`?**
* **Speed:** Filters are *extremely* fast. Elasticsearch caches them heavily.
* **UI:** They are "pills" you can click. You can add them, remove them, or temporarily disable them with a single click, without ever losing your KQL query.
* **Clarity:** It's much clearer to see 5 filter pills under your search bar than one giant, unreadable KQL query.

---

### 2. Conceptual Deep Dive: The 3 Ways to Add a Filter

Kibana gives you multiple "point-and-click" ways to add a filter. We will practice all three.

1.  **From the Field List (The "Easy Way"):**
    * You look at the field list on the left, find a field (like `client.geo.country_name`), see its "Top 5" values, and click the `+` or `-` icon next to a value.

2.  **From the Document Table (The "Contextual Way"):**
    * You expand a log by clicking the `>` caret. You see all its data. You find a field you're interested in (like `user_id: "bob"`) and click the `+` or `-` icon right next to it. This is great for "pivoting" during an investigation.

3.  **From the "Add Filter" Button (The "Power-User Way"):**
    * You click the "Add filter" button (under the KQL bar). This opens a small editor where you can *manually* build any filter you want (e.g., `field: response_time_ms`, `operator: is between`, `value: 1000 and 5000`).

---

### 3. Extensive Hands-On Lab: Mastering Filtering

**Prerequisite:**
1.  Navigate to **Discover** (☰ -> Analytics -> Discover).
2.  Select your **`access-logs*`** index pattern.
3.  Set your **Time Picker** to `January 1, 2020` to `April 1, 2020` to see all your data.
4.  Clear the KQL bar so it is empty.

---

#### 🚀 Lab 1: The Title Task (Filter for `status = 404`)

We will find all `404` logs using all three methods.

**Method A: KQL Bar (The "Old" Way)**
1.  **Action:** In the KQL bar, type `http.response.status_code: 404` and press Enter.
2.  **Result:** It works. The document table filters to your `404` logs. But your query is "stuck" in the text bar. Clear the bar.

**Method B: Field List (The "Easy" Way)**
1.  **Action:** In the **Field List** on the left, find and click `http.response.status_code`.
2.  It will expand to show the "Top 5 values." You will see `200`, `404`, `500`, etc.
3.  Hover your mouse over the `404` row.
4.  Click the small **`+` (plus) icon** that says "Filter for value."

5.  **Result:** Look under the KQL bar. A green "pill" has appeared: `http.response.status_code is 404`. Your document table is now filtered.
6.  **To Remove:** Click the `x` on the right of the pill. The filter is removed, and your data returns.

**Method C: "Add Filter" Button (The "Manual" Way)**
1.  **Action:** Click the **Add filter** button (below the KSQL bar).
2.  A pop-up editor appears. Fill it out:
    * **Field:** `http.response.status_code` (you can type to search for it)
    * **Operator:** `is`
    * **Value:** `404`
3.  Click **Save**.
4.  **Result:** The exact same `http.response.status_code is 404` pill appears.

**Conclusion:** All three methods get the same result. Method B is the fastest. Method C is the most powerful (it can do `is between`, `exists`, etc.).

---

#### 🚀 Lab 2: Mastering Positive & Negative Filters (`is` / `is not`)

Let's solve a real problem: "Why are `Chrome` users having a bad experience?"

1.  **Task:** Filter *for* `Chrome` users.
    * **Action:** In the Field List, find `user_agent.name`. Click it.
    * Hover over `Chrome` and click the **`+` (Filter for value)** icon.
    * **Result:** A pill `user_agent.name is "Chrome"` appears. You are now *only* seeing logs from Chrome.
2.  **Task:** Now, filter *out* the good requests. We only want to see errors.
    * **Action:** In the Field List, find `http.response.status_code`. Click it.
    * Hover over `200`.
    * Click the **`-` (minus) icon** that says "Filter out value."
    * **Result:** A *second* pill appears: `http.response.status_code is not 200`.
3.  **Analyze the Result:** You are now looking at a list of all logs that are:
    * (from `Chrome`) **AND** (are *not* `200` (OK) requests).
    * You have instantly built a view of all `404`, `500`, `401`, etc. errors that `Chrome` users are seeing.

---

#### 🚀 Lab 3: Mastering `exists` / `does not exist` Filters

Let's solve another problem: "Which of our traffic is anonymous vs. which is from a known referrer?"

1.  **Task:** Find all logs that came from another website.
    * **Action:** Click **Add filter**.
    * **Field:** `http.request.referrer`
    * **Operator:** `exists`
    * Click **Save**.
    * **Result:** You are now *only* seeing logs that contain the `http.request.referrer` field.

2.  **Task:** Now, find all logs that are *anonymous* (have no `user_id`).
    * **Action:** Remove the last filter. Click **Add filter**.
    * **Field:** `user_id`
    * **Operator:** `does not exist`
    * Click **Save**.
    * **Result:** You are now seeing *only* the logs that are missing a `user_id` (e.g., your "guest" or "public" traffic).

---

#### 🚀 Lab 4: The Power Workflow (KQL + Filters)

**Problem:** "A manager wants to know if any of our *admin* users are running into `404` errors."

1.  **Task 1 (KQL):** Find all "admin" users. We'll use KQL for this.
    * **Action:** In the KQL bar, type `user_id: "admin"` and press Enter.
    * **Result:** You now see all logs for the `admin` user.
2.  **Task 2 (Filter):** Now, *filter* this list to show *only* the `404` errors.
    * **Action:** In the Field List, click `http.response.status_code`, find `404`, and click the **`+`** icon.
    * **Result:** You now have:
        * **KQL:** `user_id: "admin"`
        * **Filter Pill:** `http.response.status_code is 404`
    * The document table now *only* shows logs that match *both* conditions. You have your answer: you can see exactly which `404` errors the admin user has hit.

---

### 4. Understanding the Filter "Pill" Itself

The green (or red) "pill" is an interactive object.

`[ http.response.status_code ] [ is ] [ 404 ] [ (x) ] [ (⋮) ]`

* **`http.response.status_code`**: The field.
* **`is`**: The operator.
* **`404`**: The value.
* **Clicking the Pill:** Opens the "Edit filter" pop-up.
* **Hovering the Pill:** Shows you three controls:
    1.  **Enable/Disable (Checkbox):** Click the checkbox on the left to temporarily *disable* the filter without deleting it. This is great for "what-if" analysis.
    2.  **Invert (Magnifying Glass):** Click this to instantly flip the filter. `is 404` becomes `is not 404`.
    3.  **Delete (`x`):** Permanently removes the filter.
    4.  **Pin (Pin icon):** This is an advanced feature that "pins" the filter so it stays with you even if you switch dashboards.

---

### 5. Troubleshooting & Common Mistakes

* **Problem:** "I added a filter and all my data disappeared!"
    * **Cause:** You over-filtered. Your `AND` logic is too specific.
    * **Example:** You have a filter `http.response.status_code is 404` and another filter `http.response.status_code is 200`. A log cannot be *both* `404` AND `200` at the same time, so 0 results are returned.
    * **Fix:** Check your filter pills. Make sure they make logical sense together.

* **Problem:** "I'm filtering for `user_agent.name is "Chrome"` but the KQL bar has `user_agent.name: "curl"`. Why do I see 0 results?"
    * **Cause:** The same reason. The final query is `(user_agent.name: "curl") AND (user_agent.name is "Chrome")`. A log cannot be both.
    * **Fix:** Clear your KQL bar *or* remove your filter. Understand that they work *together*.

* **Problem:** "I'm trying to filter from the Field List, but the value I want (`401`) isn't in the Top 5!"
    * **Cause:** The "Top 5" list is only a *preview*.
    * **Fix:** You must use the "Add filter" button (Method C).
        1.  Click **Add filter**.
        2.  **Field:** `http.response.status_code`
        3.  **Operator:** `is`
        4.  **Value:** `401`
        5.  Click **Save**.
    * This allows you to filter on *any* value, not just the most common ones.

---

## 📅 Save a Search in Kibana

### 1. Conceptual Deep Dive: What is a "Saved Search"?

In the previous sections, you've become an expert at finding data. You've written KQL queries, combined them with filters, and customized your document table.

**The Problem:** You close your browser. All that work is gone.

A **Saved Search** is the "Bookmark" or "Favorite" for your Discover tab. It's not just a "saved query"—it's a "snapshot" of your *entire view*.

Saving a search is the most important step for re-usability and for building dashboards.

#### What Exactly Does it Save?

When you save a search, Kibana saves a "view package" that includes:
1.  **The KQL Query:** The text in your search bar (e.g., `user_agent.name: "Chrome"`).
2.  **The Filters:** All the active "pills" (e.g., `http.response.status_code is 404`).
3.  **The Column Layout:** The fields you've added to the document table (e.g., `client.ip`, `url.path`).
4.  **The Sort Order:** The column you are sorting by (e.g., `@timestamp descending`).
5.  **The Time Range (Optional):** You can (but usually don't) save the current time range with the search.

#### Why Do We Save Searches?

There are two primary, critical reasons:

1.  **Re-Usability & Sharing (The "Debug" Case):**
    * You have a complex query you run every morning to check for errors (e.g., 1 KQL query + 4 filter pills). You don't want to rebuild that every day.
    * You **save it** as `[DEBUG] - Daily Error Check`. Now, it's a one-click action.
    * You can also send the URL of a saved search to a teammate so they see *exactly* what you see.

2.  **Building Dashboards (The "Reporting" Case):**
    * This is the **most important reason**.
    * A dashboard is a collection of panels (charts, maps, etc.). But what if you want to see the *raw logs* next to your charts?
    * You **cannot** add "the Discover page" to a dashboard. You **must** save your Discover view as a "Saved Search" first.
    * A **Saved Search** can be added to a dashboard as a panel, showing the list of raw logs. This is the topic of our next section, "Pin a saved search to dashboard."

---

### 2. Extensive Hands-On Lab: Creating & Using Saved Searches

**Prerequisite:**
1.  Navigate to **Discover** (☰ -> Analytics -> Discover).
2.  Select your **`access-logs*`** index pattern.
3.  Set your **Time Picker** to `January 1, 2020` to `April 1, 2020` to see all your data.
4.  Clear the KQL bar and remove all filters.

---

#### 🚀 Lab 1: Save a Simple "Finder" Search

**Objective:** To save a common query that we will re-use for daily checks.

1.  **Build the View:**
    * **Task:** We want a view of all critical server-side errors.
    * **KQL:** In the KQL bar, type `http.response.status_code: 5*`
    * **Action:** Press Enter. The document table will filter to all `500`, `503`, etc. logs.
2.  **Save the Search:**
    * **Action:** In the top navigation bar, click the **Save** button.
    * A "Save search" dialog will appear. 
    * **Title:** Type in `[SEARCH] - All 5xx Server Errors`.
    * **Save time range:** Leave this **OFF**. (If you turn it on, it will be "stuck" in 2020, which we don't want. We want it to use the *global* time picker).
    * **Action:** Click **Save**.
3.  **Test the Saved Search:**
    * **Action:** Clear your KQL bar (make it blank) and press Enter. You should see all your logs again.
    * **Action:** Now, click the **Open** button (right next to "Save").
    * A "Open" panel will fly out, showing a list of your saved searches. You will see `[SEARCH] - All 5xx Server Errors`.
    * **Action:** Click on the name.
    * **Result:** Your KQL bar is *instantly* repopulated with `http.response.status_code: 5*`, and your table is filtered. You've just saved yourself from re-typing a query.

---

#### 🚀 Lab 2: Save a "Report View" (Query + Columns + Sort)

**Objective:** To prove that a Saved Search saves *more* than just the query. It saves the entire *view*.

1.  **Build the View:**
    * **Task:** We want a "Large Download Report" that shows all requests over 10,000 bytes, sorted by size, with clean columns.
    * **KQL:** `http.response.body.bytes > 10000`
    * **Action:** Press Enter.
2.  **Customize the Table:**
    * **Action:** In the **Field List** on the left, add these columns by clicking the `+` on each:
        * `@timestamp`
        * `client.ip`
        * `url.path`
        * `http.response.body.bytes`
    * **Action:** In the **Field List**, find the `message` field (which is in the "Selected fields" list) and click the `-` (minus) button to remove it.
    * **Result:** You have a clean table with 4 columns.
3.  **Sort the Table:**
    * **Action:** Click the header of the `http.response.body.bytes` column. It will sort. Click it again to sort *descending* (from largest to smallest). The arrow in the header should point down.
4.  **Save the "View":**
    * **Action:** Click **Save** in the top bar.
    * **Title:** `[VIEW] - Large Downloads (by Size)`
    * **Action:** Click **Save**.
5.  **Test the "View" (The "A-ha" Moment):**
    * **Action:** Click **Open**. First, click `[SEARCH] - All 5xx Server Errors`.
    * **Result:** You see the 5xx query and the *default* table columns.
    * **Action:** Now, click **Open** again. Click `[VIEW] - Large Downloads (by Size)`.
    * **Result:** Watch the screen. *Everything* changes. The KQL bar updates, the filter pills appear (if you had any), and the document table completely re-configures itself with your 4 custom columns and your sort order. You've saved a *complete view*.

---

#### 🚀 Lab 3: Save a "Combined" Search (KQL + Filters)

**Objective:** To save a complex debugging view that uses both KQL and Filter Pills.

1.  **Build the View:**
    * **Task:** We want to find all "Failed" requests from our "payment-service".
    * **KQL:** In the KQL bar, type `failed`
    * **Filter:** In the Field List, find `service_name`, hover `payment-service`, and click the **`+`** icon.
    * **Result:** You now have:
        * **KQL:** `failed`
        * **Filter Pill:** `service_name is "payment-service"`
        * The document table shows *only* logs that match *both*.
2.  **Save the Search:**
    * **Action:** Click **Save**.
    * **Title:** `[DEBUG] - Failed Payment Service Logs`
    * **Action:** Click **Save**.

---

### 3. Managing Your Saved Searches

Now that you have three saved searches, you need to know how to manage them.

#### 3.1. The "Open" Panel
* **Action:** Click **Open**.
* This panel is your "Saved Search" library.
* **Search Bar:** At the top of this panel is a search bar. If you have 100 saved searches, you can type `[DEBUG]` to find all your debugging searches, or `payment` to find all searches related to payments.
* **Tags (Advanced):** You can add tags to your searches to organize them.

#### 3.2. How to Update / Overwrite a Saved Search

**Objective:** You made a mistake. Your `[DEBUG] - Failed Payment Service Logs` search is too broad. You *only* want to see `5xx` errors. You need to *update* your saved search.

1.  **Load the Search:**
    * **Action:** Click **Open** and click `[DEBUG] - Failed Payment Service Logs`.
2.  **Modify the Search:**
    * **Action:** The search loads (KQL `failed`, Filter `service_name...`).
    * **Action:** Add another filter. In the Field List, find `http.response.status_code`, click it, find `500`, and click the **`+`** icon.
    * **Result:** You now have 1 KQL query and 2 Filter pills. The view is *different* from what you saved.
3.  **Overwrite the Original:**
    * **Action:** Click the **Save** button.
    * **CRITICAL:** A dialog appears. It defaults to "Save as new search".
    * **Action:** **Turn ON the "Save as new" toggle? *NO*.**
    * **Action:** **Click the title `[DEBUG] - Failed Payment Service Logs`? *NO*.**
    * **Action:** Look at the bottom of the dialog. You will see an option to **"Update"** or **"Overwrite"** the existing search. (The UI for this changes slightly, but the concept is the same).
    * **In Kibana 9.x:** When you click **Save**, it will show `[DEBUG] - Failed Payment Service Logs` in the title bar. Click the **Save** button in the *dialog*. It will ask: "Save changes? This will overwrite the saved object."
    * **Action:** Click **"Save changes"**.
4.  **Test the Update:**
    * **Action:** Clear your KQL and filters. Click **Open** and load `[DEBUG] - Failed Payment Service Logs` again.
    * **Result:** It will now load with *both* filter pills (`service_name...` AND `http.response.status_code is 500`). You have successfully updated your search.

---

### 4. Troubleshooting & Common Mistakes

* **Problem:** "I saved my search, but when I load it, it says 'No results found'!"
    * **Cause:** The **Time Picker**. Your saved search (e.g., `http.response.status_code: 404`) is loaded correctly, but your global time picker is set to "Last 15 minutes." There were no `404` errors in the last 15 minutes.
    * **Fix:** A Saved Search does **not** (by default) save the time. This is a *feature*. It allows you to run the same search on "Today," "Yesterday," or "Last 7 Days." You must *always* set your Time Picker to the correct range (e.g., 2020) to find your old data.

* **Problem:** "I clicked 'Save' but it made a new search called 'Copy of [DEBUG]...'. It didn't update my old one!"
    * **Cause:** You did not click the "Overwrite" or "Save changes" option. You saved it as a new search.
    * **Fix:** Go to **Stack Management** -> **Saved Objects** (under Kibana). You can find and delete the "Copy of..." object here. Then, follow Lab 3.2 to learn how to overwrite properly.

* **Problem:** "I shared my saved search with a teammate, but they can't find it when they click 'Open'!"
    * **Cause:** Saved searches are saved *per Kibana Space*. A "Space" is like a "Folder" for all your Kibana objects (dashboards, searches, etc.). You are probably in the "Default" space, and your teammate is in a "Marketing" or "Dev" space.
    * **Fix:** For now, ensure you are both in the same "Space" (usually "Default," which you can see in the top-left corner by your user icon).

---

## 📅 Pin a Saved Search to Dashboard

### 1. Conceptual Deep Dive: What is a Kibana Dashboard?

This is the "payoff" for all your work so far.

* In **Discover**, you are an *explorer*, digging for data.
* On a **Dashboard**, you are a *story-teller*, presenting your findings.

A **Dashboard** is a collection of "panels" on a single screen. It is the "cockpit" of your operations. It provides a high-level, visual summary of your data and, most importantly, allows you to *interactively* drill down.

**The LEGO Analogy (Completed):**
* **Discover:** The box of raw, individual LEGO bricks.
* **Visualize:** A single creation (a car, a house) you build from the bricks.
* **Saved Search:** A specific *set* of bricks you've put in a bag for later.
* **Dashboard:** The entire LEGO city. It's a *collection* of your creations (visualizations) and your bags of bricks (saved searches), all arranged to tell a story.

A "Panel" is any single item on your dashboard. A panel can be:
1.  **A Visualization:** A pie chart, a line graph, a map, a data table.
2.  **A Saved Search:** A raw, interactive list of your log documents.

### 2. Conceptual Deep Dive: Why "Pin" a Saved Search?

This is the single most important concept in this lesson. Why would you put a boring list of logs on a beautiful dashboard?

**Because a chart tells you *WHAT* happened, but the logs tell you *WHY*.**

Imagine your dashboard has a pie chart showing `http.response.status_code`:
* **The Chart (The "WHAT"):** The pie chart suddenly shows a 10% slice for `500` (Server Error). You now *know* something is wrong.
* **The Logs (The "WHY"):** You look at the "Saved Search" panel right below it, which you've pre-filtered for `5xx` errors. You can immediately read the `message` field and see:
    * `message: "Critical Error: NullPointerException in payment processor"`
    * `message: "Critical Error: NullPointerException in payment processor"`
    * `message: "Critical Error: NullPointerException in payment processor"`

In 5 seconds, you've gone from "What's wrong?" (the chart) to "Why is it wrong?" (the logs). **This is the core workflow of ELK.** You *must* have the raw logs next to your aggregations to be effective.

"Pinning" a saved search is how you place that critical "Why" (the raw logs) directly into your "What" (the dashboard).

---

### 3. Extensive Hands-On Lab: Building Your First Dashboard

**Prerequisite:**
You *must* have the saved searches we created in the previous lab. For this hands-on, we will use:
1.  **`[SEARCH] - All 5xx Server Errors`**
2.  **`[VIEW] - Large Downloads (by Size)`**

#### 🚀 Lab 1: Create a Blank Dashboard

1.  Navigate to the main menu (☰) -> **Analytics** -> **Dashboard**.
2.  You will see a list of all dashboards. Click the **Create dashboard** button (top-right).
3.  You are now looking at a new, untitled dashboard. It is in **Edit Mode** by default, which is what we want.



#### 🚀 Lab 2: Add (Pin) Your First Saved Search

1.  In the center of the screen, click the **Add from Library** button.
2.  A large "Add panels" flyout will appear from the right.
3.  In the search bar at the top of this flyout, type `5xx` (or the full name `[SEARCH] - All 5xx Server Errors`).
4.  You will see your Saved Search in the list. **Click on its name.**
5.  **Result:** The panel is instantly added to your dashboard in the background. You will see a list of your `5xx` error logs.

#### 🚀 Lab 3: Add (Pin) Your Second Saved Search (The "View")

1.  **Do not** close the "Add panels" flyout yet.
2.  Clear the search bar in the flyout.
3.  Type `Large Downloads` (or the full name `[VIEW] - Large Downloads (by Size)`).
4.  You will see your second Saved Search. **Click on its name.**
5.  **Result:** The second panel is added to your dashboard.
6.  **CRITICAL:** Notice that this panel has the **custom columns** we saved (`@timestamp`, `client.ip`, `url.path`, `http.response.body.bytes`) and is sorted by size. Kibana remembered our *entire view*.
7.  Now, click the `X` in the top-right of the "Add panels" flyout to close it.

#### 🚀 Lab 4: Arrange and Save Your New Dashboard

1.  Your dashboard now has two panels, probably stacked on top of each other. Let's arrange them.
2.  **Move a Panel:** Click and hold the title bar of the `[VIEW] - Large Downloads (by Size)` panel and drag it to the right of the `[SEARCH] - All 5xx Server Errors` panel.
3.  **Resize a Panel:** Hover over the bottom-right corner of any panel until your cursor becomes a resize icon. Click and drag to make the panels larger or smaller.
4.  **Action:** Arrange your two panels so they are side-by-side and fill the screen.

5.  **Save the Dashboard:**
    * In the top-right corner of the *entire page*, click the **Save** button.
    * A "Save dashboard" dialog will appear.
    * **Title:** `[DASHBOARD] - Access Log Operations`
    * **Save time range:** Leave this **OFF**. (This is a best practice. It means the dashboard will *always* use the global time picker, not be "stuck" in one time range).
    * Click **Save**.

**Congratulations!** You are now in "View Mode." You have successfully created your first dashboard.

---

### 4. Conceptual & Hands-On Deep Dive: The MAGIC of a Dashboard (Interactivity)

This is the "A-ha!" moment. Why is a dashboard better than a static report? Because it's a *tool*, not just a picture.

You are in "View Mode" for your new `[DASHBOARD] - Access Log Operations`.

Notice the **Time Picker** and the **KQL Bar** are *still* at the top of the page. These are now **Global Controls** for *every single panel* on your dashboard.

#### 🚀 Lab 5: Using the Global KQL Bar

**Task:** "This is a great report, but I only care about the `payment-service`. Show me this *entire* dashboard, but filtered *only* for the `payment-service`."

1.  **Action:** At the *very top* of the page, in the dashboard's KQL bar, type:
    `service_name: "payment-service"`
2.  Press **Enter**.
3.  **Watch the Dashboard:**
    * The `[SEARCH] - All 5xx Server Errors` panel will *instantly* update. It now *only* shows 5xx errors from the `payment-service`.
    * The `[VIEW] - Large Downloads (by Size)` panel will *also* update. It now *only* shows large downloads from the `payment-service`.
4.  **Conclusion:** You have just used the dashboard as a *dynamic filter*. You didn't have to re-build anything. You simply added a "global filter" to your "cockpit" view.

#### 🚀 Lab 6: Using Global Filters (Pills)

**Task:** "This is great. Now, clear that. I want to see all traffic from `curl` users."

1.  **Action:** Clear the KQL bar (make it blank) and press Enter. The panels will go back to normal.
2.  **Action:** Click the **Add filter** button (under the KQL bar).
3.  A pop-up editor appears. Fill it out:
    * **Field:** `user_agent.name`
    * **Operator:** `is`
    * **Value:** `curl`
4.  Click **Save**.
5.  **Watch the Dashboard:**
    * A global filter pill `user_agent.name is "curl"` appears.
    * *Both* your panels instantly filter to show *only* data from `curl` requests. You can see all the `5xx` errors from `curl` and all the "Large Downloads" from `curl`.

#### 🚀 Lab 7: Using the Global Time Picker

**Task:** "This 2020 data is fine for a lab, but I want to see what's happening *right now*."

1.  **Action:** Click the **Time Picker** in the top-right corner.
2.  Click **Quick select**.
3.  Click **Today**.
4.  **Result:** The dashboard updates. Both panels now show "No results found." **This is not an error!** This is *correct*. You have told your dashboard to show you data *only* from `today`, but your data is from 2020. This proves that the dashboard is a live, dynamic tool, not a static report.
5.  **Action:** To fix it, click the Time Picker again and set it back to your 2020 dates.

---

### 5. Troubleshooting & Common Mistakes

* **Problem:** "I went to 'Add from Library,' but I can't find my Saved Search!"
    * **Cause 1:** You didn't save it. You clicked "Save" on the *dashboard*, but you forgot to click "Save" on the *Discover* page first.
    * **Fix 1:** Go back to Discover (☰ -> Analytics -> Discover), build your view, and **Save** it.
    * **Cause 2 (Advanced):** You are in a different **Kibana Space**. Spaces are like "folders" for dashboards. If you saved your search in the "Default" space but are building your dashboard in the "Marketing" space, you won't see it.
    * **Fix 2:** For now, always make sure you are in the same Space (usually "Default").

* **Problem:** "I added my Saved Search, but the custom columns I wanted (`client.ip`, etc.) are gone! It just shows `Time` and `message`."
    * **Cause:** You did not save the columns correctly. You went to Discover, added the columns, and then clicked "Save" to save the *dashboard panel*. You forgot the critical step.
    * **Fix:**
        1.  Go back to **Discover**.
        2.  **Load** your saved search (e.g., `[VIEW] - Large Downloads...`).
        3.  Add the columns you want (`client.ip`, `url.path`, etc.).
        4.  Click **Save** (in the Discover app).
        5.  An "Update search?" dialog will appear. Click **"Save changes"** to *overwrite* your search.
        6.  Now, go back to your dashboard. The panel will automatically update with the new columns.

* **Problem:** "My dashboard panel is stuck in 2020. When I change the Global Time Picker, it doesn't update!"
    * **Cause:** You accidentally clicked the "Save time range" toggle when you saved your *search*. Your search is now "stuck" in 2020, ignoring the dashboard's global time.
    * **Fix:** Go to **Discover**, **Open** your search, click **Save**, and make sure the **"Save time range"** toggle is **OFF**. Re-save the search.

---

