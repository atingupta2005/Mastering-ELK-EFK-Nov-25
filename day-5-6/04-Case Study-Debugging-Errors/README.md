## 📅 Case Study: Debugging a Failed Transaction

**Objective:** This is a capstone lab that combines all the skills you have learned: querying, filtering, and cross-index correlation. You will act as an analyst to trace a production error from its symptom to its root cause and business impact.

**The Scenario:**
A monitoring alert has triggered for `500` (Internal Server Error) status codes on the `payment-service`. We must investigate.

**Our Goal:**

1.  Find the specific error logs.
2.  Filter to find the cause and the affected users.
3.  Correlate this IT failure with business data (from the `orders` index) to understand the real-world impact.

**The Assumption:** For this lab, we will assume that the `user_id` field in the `access-logs*` index pattern maps directly to the `customer.id` field in the `orders*` index pattern.

-----

### 1\. Simulate Service Logs Ingestion

**Conceptual Overview:**
In this context, "simulating ingestion" means running the initial, broad query to find the "symptom" logs. Our monitoring alert told us `500` errors are happening on the `payment-service`. This is our starting point. We will use the `access-logs` to find the raw operational data.

**Hands-On Lab: Finding the Symptom**

1.  **Action: Select Data Source and Time**

      * Navigate to **Discover** (☰ -\> Analytics -\> Discover).
      * Select the **`access-logs*`** index pattern.
      * Set your **Time Picker** to the absolute range of your 2020 sample data (e.g., `Jan 1, 2020` to `Apr 1, 2020`).

2.  **Action: Find the Initial Error Logs**

      * In the KQL search bar, type the query for our symptom:
        `service_name: "payment-service" and http.response.status_code: 500`
      * Press Enter.

3.  **Analyze the Result:**

      * The document table will filter down to show *only* the `500` errors from the `payment-service`.
      * In the sample data, this will isolate `recap-003`.
      * Expand this log document by clicking the `>` caret.

4.  **Information Gathered (The "Ingestion"):**
    By "ingesting" this one log, we have gathered three critical clues for our investigation:

      * **The User:** `user_id: "bob"`
      * **The Time:** `@timestamp: "2025-11-09T11:01:00Z"` (Note this exact time)
      * **The URL:** `url.path: "/api/v2/payment/process"`

-----

### 2\. Filter Logs

**Conceptual Overview:**
"Filtering" is the process of drilling down and pivoting. We've identified a user, "bob," and a specific time. Now we need to filter our logs to see *only* his activity to understand what led to the failure.

**Hands-On Lab: Filtering for User Context**

1.  **Task:** We must trace `user_id: "bob"`'s entire session, not just the one error.
2.  **Action: Clear the KQL Bar**
      * Clear the KQL bar (remove the `service_name...` query) and press Enter. You are now seeing all logs.
3.  **Action: Add a User Filter**
      * In the **Field List** on the left, find and click `user_id`.
      * In the Top 5 list, find `bob` and click the **`+` (Filter for value)** icon.
      * A pill `user_id is "bob"` will be added.
4.  **Analyze the Result:**
      * The document table now shows *only* logs from `user_id: "bob"`.
      * The logs are sorted by time (by default). You can now read the *story* of Bob's session:
        1.  `11:01:00Z`: `POST /api/v2/payment/process` (Status `500`)
        2.  `11:03:00Z`: `GET /api/v1/health` (Status `200` - This is from `service_name: "api-gateway"`, not from Bob's client, but his `user_id` might be associated if it's part of the same trace)
        3.  `11:08:05Z`: `POST /api/submit_payment` (Status `200`)
        4.  `11:20:15Z`: `GET /profile` (Status `200`)
        5.  `11:21:00Z`: `GET /admin/dashboard` (Status `403`)
      * **Conclusion from Filtering:** We see Bob's `500` error at 11:01:00. We *also* see a *successful* payment (`200`) at 11:08:05. This is a critical new clue.

-----

### 3\. Correlate with Error Messages

**Conceptual Overview:**
Now we must correlate all our findings. We have two key events for `user_id: "bob"`:

  * Event A (The Failure): 11:01:00Z - `POST /api/v2/payment/process` - Status `500`
  * Event B (The Success): 11:08:05Z - `POST /api/submit_payment` - Status `200`

We need to know the *reason* for the failure (the error message) and the *business impact* (did an order get created?).

#### 🚀 Lab 1: Correlate with the Error Message (The "Why")

1.  **Task:** Find the specific error message for the `500` failure.
2.  **Action:** We will use a KQL query to find the *exact* log.
    ```kql
    user_id: "bob" and http.response.status_code: 500
    ```
3.  **Analyze:** This will show the single log `recap-003`. Expand it.
4.  **Find the Correlation:** Look at the `message` field.
      * **Message:** `"Critical Error: NullPointerException in payment processor. Payment failed."`
5.  **Conclusion:** We have correlated the `500` status with a specific, actionable error. We can now file a bug report for the development team: "The `payment-service` threw a `NullPointerException` at 11:01:00 on the `/api/v2/payment/process` endpoint."

#### 🚀 Lab 2: Correlate with Business Impact (The "So What?")

**This is the final and most important step.** We know the error. But what was the *business impact*? Did Bob get charged? Was an order created? For this, we must switch to our `orders*` index.

1.  **Task:** Find any order created for `customer.id: "bob"` at the *exact time* of the failure.
2.  **Action: Switch Index Pattern**
      * In the top-left dropdown, change your index pattern from `access-logs*` to **`orders*`**.
3.  **Action: Set the Time Window**
      * Click the **Time Picker**.
      * Select the **Absolute** tab.
      * We will "bracket" the failure time (`11:01:00`).
      * **Start:** `January 15, 2020 @ 11:00:00.000` (Use the date from your sample data)
      * **End:** `January 15, 2020 @ 11:02:00.000`
      * Click **Update**. You are now looking at a 2-minute window.
4.  **Action: Filter for the Customer**
      * In the KQL bar, type: `customer.id: "bob"`
      * Press Enter.
5.  **Analyze the Result:** The screen will show **"No results found."**
6.  **Final Correlation (The "Case Closed" Moment):**
      * **Fact 1:** At 11:01:00, the `access-logs` show `user_id: "bob"` got a `500 - NullPointerException` on the payment URL.
      * **Fact 2:** At 11:01:00, the `orders` index shows *no order* was created for `customer.id: "bob"`.
      * **Case Conclusion:** We can confidently report to management: "At 11:01 AM, user 'bob' experienced a `NullPointerException` while trying to check out. Our `orders` index confirms **no order was created** and **no sale was recorded** for this failed transaction." We can also see from our earlier filtering (Lab 2) that Bob *tried again* at 11:08 and was successful.