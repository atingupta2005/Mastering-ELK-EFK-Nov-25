## 📅 Day 4: Discover Tab – Exploring Logs

### 1. Discover Tab Layout

#### Conceptual Overview
The **Discover** application is the primary interface in Kibana for interactively exploring your log data. It is the "command center" for analysts. Before you can build any charts or dashboards, you must first come here to understand your data, find patterns, and validate hypotheses.

The layout is comprised of five key components:



1.  **The Index Pattern Selector (Top-Left):** This dropdown menu is how you select your data source. You must choose which index pattern (e.g., `access-logs*` or `orders*`) you want to explore.
2.  **The Time Picker (Top-Right):** This is the master time filter for your view. It controls the time range for the histogram, the document table, and all searches. This is the most common source of the "No results found" error (e.g., searching for 2020 data while the picker is set to "Last 15 minutes").
3.  **The KQL Search Bar (Top):** This is your primary "finder" tool. You write **KQL (Kibana Query Language)** queries here to search your data.
4.  **The Field List (Left Sidebar):** This is your "data menu." It lists every field (e.g., `client.ip`, `http.response.status_code`) from your index pattern. You can use this list to filter data and customize your view.
5.  **The Main Content Area (Center):** This area has two parts:
    * **The Histogram:** A bar chart showing the *count* of log documents over your selected time. This is your "spike detector."
    * **The Document Table:** The row-by-row list of individual log documents that match your search.

####  Hands-On: Get Oriented

1.  Navigate to the main menu (☰) -> **Analytics** -> **Discover**.
2.  **Select Index Pattern:** In the top-left dropdown, select `access-logs*`.
3.  **Set Time Range:** In the top-right Time Picker, click it. Select the **Absolute** tab.
    * Set **Start date** to `January 1, 2020 @ 00:00:00.000`
    * Set **End date** to `April 1, 2020 @ 00:00:00.000`
    * Click **Update**.
4.  **Observe:** You should now see the histogram fill with data, and the document table below it will populate with your `access-logs` data from 2020. You are now ready to search.

---

### 2. Using the Search Bar Effectively

#### Conceptual Overview
The search bar uses **KQL (Kibana Query Language)**. It's a simple and powerful syntax for finding specific data. There are two primary ways to search.

* **Free-Text Search:**
    * **Query:** `failed`
    * **Action:** Kibana searches *all* fields mapped as `text` for the word "failed." In your `access-logs` schema, this includes `message`, `url.original.text`, `user_agent.original.text`, etc. This is a broad "best guess" search.

* **Field-Based Search (The "Professional" Method):**
    * **Query:** `http.response.status_code: 404`
    * **Action:** This is a precise and highly efficient query. It *only* searches the `http.response.status_code` field for the value `404`. This is the method you will use 99% of the time.

**KQL Core Operators (Syntax):**

| Operator | Purpose | Example (using `access-logs` schema) |
| :--- | :--- | :--- |
| `:` | Separates field and value | `http.request.method: POST` |
| `and` | (Default) All terms must match. | `user_agent.name: "Chrome" and client.geo.country_name: "China"` |
| `or` | At least one term must match. | `http.response.status_code: 500 or http.response.status_code: 503` |
| `not` | Excludes documents with this term. | `http.response.status_code: 200 and not user_id: "system"` |
| `()` | Groups logic together. | `(http.response.status_code: 401 or 403) and http.request.method: POST` |
| `>` `<=` | Range operators for numbers/dates. | `http.response.body.bytes > 10000` |
| `*` | Exists operator. | `http.request.referrer: *` (finds all logs that *have* a referrer) |
| `""` | Phrase operator. | `message: "Invalid password"` (finds this exact phrase, not "invalid" or "password" separately) |

####  Extensive Hands-On Lab: KQL Search Drills

*(**Setup:** Ensure you are in Discover, with `access-logs*` selected and the Time Picker set to Jan-Apr 2020).*

* **Drill 1: Find all `POST` requests.**
    * **KQL:** `http.request.method: POST`
    * **Result:** The table filters to show only logs where the request method was `POST`.

* **Drill 2: Find all `404` (Not Found) errors.**
    * **KQL:** `http.response.status_code: 404`
    * **Result:** The table filters to show only logs with a `404` status.

* **Drill 3: Find all "critical" server errors.**
    * **KQL:** `http.response.status_code: 5*`
    * **Result:** The KQL wildcard `*` works on number fields. This will find all `500`, `502`, `503` errors, etc.

* **Drill 4: Find all "slow" requests.**
    * **KQL:** `http.response.body.bytes > 5000`
    * **Result:** A list of all requests that returned a response larger than 5000 bytes.

* **Drill 5: Find a specific phrase.**
    * **Task:** Find *only* the logs for "Invalid password" attempts.
    * **KQL:** `message: "Invalid password"`
    * **Result:** Finds only logs with that *exact phrase*. If you had searched `message: Invalid password` (no quotes), it would have found logs with "Invalid" *or* "password", which is too broad.

* **Drill 6: Find complex "AND" logic.**
    * **Task:** Find all `404` errors that came from a `Chrome` browser.
    * **KQL:** `http.response.status_code: 404 and user_agent.name: "Chrome"`

* **Drill 7: Find complex "OR" / "AND" logic.**
    * **Task:** Find all `401` (Unauthorized) or `403` (Forbidden) logs that were *also* `POST` requests.
    * **KQL:** `(http.response.status_code: 401 or http.response.status_code: 403) and http.request.method: POST`
    * **Result:** This finds a very specific, high-priority list of potentially malicious activity.

---

### 3. Expanding and Viewing Documents

#### Conceptual Overview
The document table, by default, only shows you a summary (e.g., the `@timestamp` and `message` fields). To debug, you *must* see all the data for a single log event.

When you expand a log, Kibana shows you the data in two formats:

1.  **Table View:** A clean, two-column table of `Field` and `Value`. This is the easiest way to read all 27+ fields.
2.  **JSON View:** The raw, nested JSON object that is stored in Elasticsearch. This is useful for developers and for seeing the *true* structure of the data.

####  Hands-On Lab: Document Inspection and Table Customization

* **Drill 1: Expand a log and inspect its fields.**
    1.  **Action:** In the document table, find any log and click the `>` caret on the far left.
    2.  **Observe:** The row expands. You will see the **Table** view by default. Scroll down to see all the fields: `client.ip`, `client.geo.city_name`, `url.path`, `user_agent.original`, etc.
    3.  **Action:** At the top of this expanded view, click the **JSON** tab.
    4.  **Observe:** You now see the raw `_source` document, which is how Elasticsearch stores it.

* **Drill 2: Customize the Main Document Table (CRITICAL skill).**
    * **Task:** The default "Time" and "message" columns are not very useful. Let's create a clean "Security View."
    1.  **Action:** In the **Field List** on the left, find `@timestamp`. Hover over it and click the `+` (plus) button.
    2.  **Observe:** The `@timestamp` field is added as a column to your table.
    3.  **Action:** Repeat this, clicking the `+` button for the following fields:
        * `client.ip`
        * `user_id`
        * `http.request.method`
        * `http.response.status_code`
        * `url.path`
    4.  **Action:** Now, find the `message` field in the "Selected Fields" list (at the top of the sidebar) and click its `-` (minus) button to remove it.
    5.  **Result:** You now have a clean, easy-to-read, 6-column table. This custom view is *much* more useful for analysis. You can also drag the column headers to re-order them.

---

### 4. Filtering Logs by Field

#### Conceptual Overview: KQL vs. Filters (The "Why")
This is the most important concept in Discover.
* **KQL Bar:** This is a "Scoring" search (`Query Context`). It's for `text` fields and complex logic.
* **Filters:** These are "Yes/No" searches (`Filter Context`). They are for `keyword` or `number` fields.

**Why are Filters (Pills) better?**
1.  **They are FASTER:** Filters are cached by Elasticsearch. A filter for `http.response.status_code: 404` is much faster than a KQL query for it.
2.  **They STACK:** You can add multiple filter "pills" (e.g., `status: 404` + `user: "bob"` + `country: "China"`) and easily enable, disable, or remove them one by one.
3.  **They are "AND"ed:** Your final search is `(KQL Query) AND (Filter 1) AND (Filter 2)`.

####  Extensive Hands-On Lab: The 3 Ways to Filter

*(**Setup:** Clear your KQL bar so it's empty. Ensure your time is set to 2020.)*

* **Drill 1: Filter from the Field List (The Easiest Way)**
    * **Task:** Show *only* `404` errors.
    1.  **Action:** In the **Field List** (left), find and click `http.response.status_code`.
    2.  **Observe:** It shows the "Top 5 values" (`200`, `404`, `500`, etc.).
    3.  **Action:** Hover over the `404` row and click the **`+` (Filter for value)** icon.
    4.  **Result:** A green "pill" (`http.response.status_code is 404`) appears under the search bar. Your table is now filtered.

* **Drill 2: Add a Negative Filter**
    * **Task:** Show all `404` errors that were *not* from a `GET` request.
    1.  **Action:** (Leave the `404` filter on). In the Field List, find and click `http.request.method`.
    2.  **Action:** Hover over the `GET` row and click the **`-` (Filter out value)** icon.
    3.  **Result:** A *second* pill (`http.request.method is not GET`) appears. Your data is now filtered for *both* conditions.

* **Drill 3: Filter from the Document Table (The "Pivot")**
    * **Task:** Find all logs from the *exact same browser* as a specific log.
    1.  **Action:** Clear all filters.
    2.  **Action:** Expand any log document by clicking `>`.
    3.  **Action:** In the **Table** view, find the `user_agent.name` field (e.g., `user_agent.name: "Chrome"`).
    4.  **Action:** Hover over that row and click the **`+` (Filter for value)** icon on the right.
    5.  **Result:** A pill (`user_agent.name is "Chrome"`) is added. This is called "pivoting"—you found one piece of data and used it to find all *other* data that matches it.

* **Drill 4: Combine KQL *and* Filters (The "Pro" Workflow)**
    * **Task:** Find all "failed" log messages that *only* came from the `payment-service`.
    1.  **Action (KQL):** In the KQL bar, type `message: "failed"` and press Enter. (This is a "scoring" search).
    2.  **Action (Filter):** In the Field List, find `service_name`, click it, find `payment-service`, and click the **`+`** icon. (This is a "filtering" search).
    3.  **Result:** You now have the KQL query *and* the filter pill working together. This is the most efficient way to search: use KQL for broad `text` search and filters for precise `keyword` narrowing.

---

### 5. Saving a Search for Later Use

#### Conceptual Overview
You just built a complex, valuable view (KQL + Filters + Custom Columns). You must save this work.

A **Saved Search** is a "bookmark" of your *entire* Discover view. It saves:
* The KQL query.
* All the Filter pills.
* The custom columns you selected.
* The sort order.

You save a search for two reasons:
1.  **Re-usability:** To run the same "Daily Error Report" every morning with one click.
2.  **Dashboards:** You **must** save a search before you can add it as a "raw log" panel to a dashboard.

####  Hands-On Lab: Save and Load Your Views

* **Drill 1: Save a "Search" (e.g., Critical Errors)**
    1.  **Action (Build):** Clear all filters. In KQL, type `http.response.status_code: 5*`.
    2.  **Action (Save):** In the top toolbar, click **Save**.
    3.  **Title:** `[SEARCH] - All 5xx Server Errors`
    4.  **Action:** Click **Save**.

* **Drill 2: Save a "View" (e.g., Custom Table)**
    1.  **Action (Build):** Clear all filters and KQL.
    2.  Add the custom columns from Drill 2: `@timestamp`, `client.ip`, `user_id`, `http.request.method`, `http.response.status_code`, `url.path`.
    3.  **Action (Save):** Click **Save**.
    4.  **Title:** `[VIEW] - Clean Security Table`
    5.  **Action:** Click **Save**.

* **Drill 3: Load Your Saved Searches**
    1.  **Action:** In the top toolbar, click **Open**.
    2.  A flyout will appear. Click on `[SEARCH] - All 5xx Server Errors`.
    3.  **Observe:** The page reloads. The KQL bar is filled (`http.response.status_code: 5*`) and the table uses the *default* columns.
    4.  **Action:** Click **Open** again. Click on `[VIEW] - Clean Security Table`.
    5.  **Observe:** The page reloads. The KQL bar is *empty*, but the **table has your 6 custom columns**.

This proves that a Saved Search saves your *entire* context, making it a powerful tool for re-using your work.