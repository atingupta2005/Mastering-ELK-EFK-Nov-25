## 📅 Day 5: Hands-On with Queries

**The Scenario:** You are an analyst. A ticket has come in: "The site is slow, and users are reporting errors." Your job is to find the errors, isolate them, and create a report.

**Prerequisite:**

  * You are in the **Discover** application (☰ -\> Analytics -\> Discover).
  * Your Index Pattern is set to **`access-logs*`**.
  * Your **Time Picker** is set to an absolute range that includes all your `access-logs` data (e.g., `January 1, 2020` to `April 1, 2020`).

-----

### 1\. Search logs for “ERROR” keyword (Topic 16)

**Conceptual Overview:**
The investigation starts with a broad, free-text search. The user reported "errors," so our first step is to find any log that *contains* the word "error" or a related term. This is a full-text search, which should be performed on the `message` field (a `text` field).

**Hands-On Lab:**

1.  **Action:** In the KQL search bar, type a simple `text` query:

    ```kql
    message: "error"
    ```

    *Note: This will find "error", "Error", "ERROR", etc., as the field is analyzed.*

2.  **Analyze:** This will return a list of logs. You might see `recap-003` ("Critical Error...") and `recap-012` ("Internal Server Error..."). This is a good start, but it's "slow" (a `text` search) and might miss errors that don't have this exact word.

3.  **Action (Refine):** Let's try a more specific phrase search based on our findings.

    ```kql
    message: "Critical Error"
    ```

4.  **Analyze:** This will narrow your results down significantly, likely to `recap-003`. This is a good way to find a *specific* error, but a *better* way to find *all* errors is to use the status code.

-----

### 2\. Find logs where status = 500 (Topic 17)

**Conceptual Overview:**
A text search for "error" is unreliable. The *reliable* way to find server errors is to query the `http.response.status_code` field, which is a `long` (a number).

The most common server error is `500` (Internal Server Error). The *best* way to find *all* server errors is to search for the entire `5xx` range.

**Important:** You cannot use a wildcard (`5*`) on a number field. You must use a range query.

**Hands-On Lab:**

1.  **Action (Find a specific error):** Clear the KQL bar. Type:

    ```kql
    http.response.status_code: 500
    ```

2.  **Analyze:** The document table filters to show *only* logs with the `500` status. This is a very fast and precise query.

3.  **Action (Find *all* server errors):** This is the "professional" query for this problem.

    ```kql
    http.response.status_code >= 500 and http.response.status_code <= 599
    ```

4.  **Analyze:** The document table now shows *all* `5xx` errors, including `500` (Internal Server Error) and `503` (Service Unavailable). This is the query we will use for our report.

-----

### 3\. Filter logs by time range (Topic 18)

**Conceptual Overview:**
You've found *what* is failing. Now you need to find out *when*. You've already set your *global* time range (to 2020), but now you need to "zoom in" on the *specific* time of the failures.

There are three ways to do this:

1.  **The Time Picker (Global):** What you already did (set to 2020).
2.  **The Histogram (Interactive Zoom):** The fastest way to "zoom in."
3.  **KQL (Manual Override):** Adding a time range directly to your query.

**Hands-On Lab:**

1.  **Action (Prepare):** In the KQL bar, have your query from the last step active:
    `http.response.status_code >= 500 and http.response.status_code <= 599`

2.  **Observe:** Look at the **Discover Histogram** (the bar chart at the top). It is now *only* showing the spikes for `5xx` errors. You can see they only happened on one or two specific days.

3.  **Action (Method 2: Interactive Zoom):**

      * On the **Histogram**, find the bar that shows your spike of errors.
      * **Click and drag** your mouse to select a small window just around that bar (e.g., a 10-minute range).
      * When you release the mouse, the **Time Picker** will *automatically* update to this new, small time range.

4.  **Analyze:** The document table now shows *only* the `5xx` logs from that 10-minute window. You have successfully "zoomed in" on the failure event.

5.  **Action (Method 3: KQL Override):**

      * **Reset** your Time Picker (click the zoom-out icon or re-select your 2020 range).
      * **Add** a time range *directly* to your KQL query (adjust the time to match your data spike):

    <!-- end list -->

    ```kql
    (http.response.status_code >= 500 and http.response.status_code <= 599) and @timestamp >= "2020-01-15T10:00:00Z" and @timestamp <= "2020-01-15T11:00:00Z"
    ```

6.  **Analyze:** This query *overrides* the Time Picker and will *only* show errors from that specific 1-hour window. This is very useful for saving in reports.

-----

### 4\. Save a query as saved search (Topic 19)

**Conceptual Overview:**
You have built a very useful, complex view to find all server errors. You don't want to re-type this every day. You will **save** this view. A **Saved Search** (now "Saved View") captures your *entire* context:

  * The KQL query.
  * All active Filter pills.
  * The custom columns in your document table.
  * The sort order.

**Hands-On Lab:**

1.  **Action (Step 1: Build the View):** Let's create our final, perfect view for a "Critical Errors Report."
      * **KQL Bar:** `http.response.status_code >= 500 and http.response.status_code <= 599`
      * **Filter Pill (Drill-down):** Let's narrow this down. In the **Field List** (left), click `service_name`, find `payment-service`, and click the **`+` (Filter for value)** icon.
      * **Customize Columns:** In the Field List, add (`+`) the following columns:
          * `client.ip`
          * `url.path`
          * `service_name`
          * `http.response.status_code`
          * `message`
      * **Remove** the default `_source` column if it's there.
2.  **Action (Step 2: Save the View):**
      * In the top toolbar, click the **Save** button.
      * **Title:** `[REPORT] - Critical Payment Service Errors (5xx)`
      * **Save time range:** Leave this toggle **OFF**. This is a best practice, so the view always uses the dashboard's global time.
      * Click **Save**.
3.  **Action (Step 3: Test the Saved Search):**
      * Click **Clear** at the top of the Discover page (or refresh the browser). Everything is reset.
      * In the top toolbar, click **Open**.
      * Click on your saved search: `[REPORT] - Critical Payment Service Errors (5xx)`.
      * **Analyze:** The *entire view* is rebuilt instantly: The KQL is in the bar, the filter pill is active, and your custom 5-column table is perfectly arranged.

-----

### 5\. Export results as CSV (Topic 20)

**Conceptual Overview:**
Your "Critical Payment Service Errors" report is saved. Now, your manager (who does not use Kibana) wants this report in a spreadsheet. You must export it.

Kibana's reporting is a **background task**. This is because a query might return 10 million logs, which your browser cannot download directly.

1.  You **request** a report.
2.  Kibana builds it on the **server** in the background.
3.  You **download** the finished file from the **Reporting** management page.

**Hands-On Lab:**

1.  **Action (Step 1: Load the View):**
      * Click **Open** and load your `[REPORT] - Critical Payment Service Errors (5xx)` saved search.
      * **This is critical:** The CSV export will use your *current* view. This means it will *only* export the `5` custom columns you saved, not all 27 fields. This is exactly what you want.
2.  **Action (Step 2: Generate the Report):**
      * In the top toolbar, click the **Reporting** button.
      * A menu will open. Click **"Generate CSV"**.
      * A pop-up will appear. Leave the toggles as-is and click **Generate**.
      * A small toast notification will pop up in the corner, confirming your report is being generated and that you can find it in **Stack Management**.
3.  **Action (Step 3: Download the Report):**
      * Navigate to **Stack Management** (☰ -\> Management -\> Stack Management).
      * Under "Kibana," click **Alerts and Reports** -\> **Reporting**.
      * You will see your report at the top of the list. Its "Status" will be "Completed".
      * On the far right, click the **Download** icon (a downward-facing arrow).
4.  **Action (Step 4: Verify the CSV):**
      * Open the downloaded CSV file in Excel or Google Sheets.
      * **Analyze:** You will see a perfect spreadsheet. The headers match your 5 custom columns (`client.ip`, `url.path`, etc.), and the data matches your query (only `5xx` errors from the `payment-service`).