## 📅 Hands-On Analysis: Debugging Failed Transactions

**Objective:** To perform a complete, end-to-end analysis workflow. We will start with a problem ("transactions are failing"), find the specific logs, isolate the cause, and prepare the findings to be shared.

**Data Source:** For this lab, we will use the **`access-logs*`** index pattern, as "failed transactions" are operational errors (like a `500` status code on a payment URL) found in log files.

---

### 1. Create Index Pattern

#### Prerequisite Check
Before you can begin this lab, you must have an index pattern for your access logs.
* **If you have not done this:** Go to **Stack Management** -> **Index Patterns** -> **Create index pattern**.
    1.  **Name:** `access-logs*`
    2.  **Next step**.
    3.  **Time field:** `@timestamp`
    4.  **Create index pattern**.
* **If you have done this:** You are ready to proceed.

**Action:**
1.  Navigate to **Discover** (☰ -> Analytics -> Discover).
2.  In the top-left index pattern selector, ensure **`access-logs*`** is chosen.
3.  In the top-right **Time Picker**, set an absolute range that includes your 2020 data (e.g., `Jan 1, 2020` to `Apr 1, 2020`).

---

### 2. Search for Failed Transactions

#### Conceptual Overview
"Failed transactions" is a business problem, not a single log entry. We must translate this problem into a specific KQL query.

What defines a "failed transaction" in our `access-logs` data?
1.  It's an **error**, so the status code is not `200`. It's probably a `5xx` (server error) or `4xx` (client error).
2.  It's a **transaction**, so it probably hits a specific API endpoint, like `/api/v2/payment/process` or `/api/submit_payment`.

Our task is to build a query that finds logs matching *both* of these conditions.

#### 🚀 Hands-On Lab: Building the "Failed Transaction" Query

**Lab 1: Find *All* Server Errors**
Let's start broadly to see all critical errors.
1.  **Action:** In the KQL search bar, type:
    `http.response.status_code: 5*`
2.  **Analyze:** You will see all logs with a `500`, `503`, etc. status. This is a good start, but it's too broad. It includes errors from all services, not just transactions.

**Lab 2: Find *All* Payment-Related Logs**
Now let's try the other way. Let's find *all* logs (errors or not) related to payments.
1.  **Action:** Clear the KQL bar. Use a wildcard `*` to find any `url.path` that contains the word "payment".
    `url.path: *payment*`
2.  **Analyze:** This is also a useful view. You can see *all* payment-related traffic, including successful `200` logs and failed `5xx` logs.

**Lab 3: Combine for the Precise "Failed Transaction" Query**
Now we combine both concepts to find the *exact* logs we need.
1.  **Task:** Find all logs that are server errors (`5xx`) AND are related to a payment URL.
2.  **Action:** In the KQL bar, type the combined query:
    `http.response.status_code: 5* and url.path: *payment*`
3.  **Analyze:** You have now isolated the *exact* "failed transaction" logs. You will see the `recap-003` (`POST /api/v2/payment/process`, status `500`) and `recap-013` (`POST /api/v2/payment/refund`, status `503`) logs. This is your core dataset for debugging.

---

### 3. Filter by Specific User ID

#### Conceptual Overview
You've found *that* transactions are failing. The next question is *who* is affected? Is it one user or all users?

We will now "drill down" by adding a filter for a specific `user_id`. We will *add* this as a **Filter Pill**, which is the correct workflow. This keeps our base KQL query separate from our specific filter, making it easy to change the user we are investigating.

#### 🚀 Hands-On Lab: Adding the User Filter

1.  **Action:** **Do not clear your KQL bar.** Keep the `http.response.status_code: 5* and url.path: *payment*` query active.
2.  **Analyze the Data:** Look at the (very small) list of failed transactions. You will see one for `user_id: "bob"` and one for `user_id: "admin"`.
3.  **Task:** Let's isolate *only* the failed transactions for "bob".
4.  **Action:** In the **Field List** on the left, find and click `user_id`.
5.  Hover over `bob` in the Top 5 list and click the **`+` (Filter for value)** icon.
6.  **Analyze the Result:** Look at your search bar. You now have *both* your KQL query *and* a filter pill:
    `[ http.response.status_code: 5* and url.path: *payment* ] [ user_id is "bob" ]`
7.  The document table has filtered again, and you now see *only* the one failed transaction for `user_id: "bob"` (`recap-003`). You have successfully drilled down.

**Lab 2: Pivoting to Another User**
1.  **Task:** Now, you want to see the failed transactions for "admin".
2.  **Action:** Do *not* change the KQL. Simply click the `user_id is "bob"` pill.
3.  In the pop-up, click **Edit filter**.
4.  Change the **Value** from `bob` to `admin`.
5.  Click **Save**.
6.  **Analyze:** The pill is now `user_id is "admin"`, and your document table instantly updates to show the `recap-013` log. You are now using the filter pills to "pivot" between different users while keeping your base query intact.

---

### 4. Save Filtered Results

#### Conceptual Overview
You have created a very valuable view: `(KQL: 5xx errors on payment URLs) AND (Filter: user_id is "admin")`.

This is a complete "finding." You must now save it. As we learned, a **Saved Search** (now "Saved View") saves *everything*: the KQL, the filters, and the custom columns.

#### 🚀 Hands-On Lab: Saving Your Analysis

1.  **Action (Step 1: Build the Full View):**
    * Load your query: `http.response.status_code: 5* and url.path: *payment*`
    * Add your filter: `user_id is "admin"`
    * **Customize Columns:** Let's make a clean table. In the Field List, add (`+`) the following:
        * `@timestamp`
        * `service_name`
        * `client.ip`
        * `url.path`
        * `http.response.status_code`
        * `message`
    * Remove any other columns (like `_source`) to make it clean.
2.  **Action (Step 2: Save the View):**
    * In the top toolbar, click the **Save** button.
    * **Title:** `[DEBUG] - Failed Admin Transactions`
    * **Save time range:** Leave this toggle **OFF**.
    * Click **Save**.
3.  **Action (Step 3: Test It):**
    * Click **Clear** at the top of the Discover page to reset everything.
    * Click **Open**.
    * Click on your new saved search: `[DEBUG] - Failed Admin Transactions`.
    * **Result:** Your entire view is restored—the KQL, the filter pill, and your 6 custom columns.

---

### 5. Share Saved Search Link

#### Conceptual Overview
You have found the exact error log for the admin. Now you need to share this *specific finding* with another analyst on your team. A CSV export is static. You want to send them an *interactive link* that takes them to the exact same screen you are looking at. This is a **Permalink**.

#### 🚀 Hands-On Lab: Sharing Your Finding

1.  **Action (Step 1: Load the View):**
    * Make sure your `[DEBUG] - Failed Admin Transactions` saved view is loaded.
2.  **Action (Step 2: Generate the Link):**
    * In the top toolbar, click the **Share** button.
    * A "Share" pop-up will appear.
3.  **Analyze the Options:**
    * **Permalink:** This is the one you want. It generates a link to your saved view.
    * **Short URL:** This generates a *very long* URL that encodes all your KQL, filters, and time settings *directly* into the link. This is good for ad-hoc sharing, but a permalink is cleaner.
4.  **Action (Step 3: Copy the Link):**
    * Select the **Permalink** option.
    * Click the **"Copy link"** button.
5.  **Action (Step 4: Test the Link):**
    * Open a new, incognito browser window (or send the link to a teammate).
    * Paste the URL in the address bar and press Enter.
    * **Result:** After logging in, Kibana will take you *directly* to the Discover app with the `[DEBUG] - Failed Admin Transactions` view loaded, complete with the KQL, filter pill, and custom columns. You have successfully shared your finding.