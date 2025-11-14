## 📅 Day 5: Log Analysis Basics - Spotting Spikes in Errors

### 1\. Conceptual Overview: What is a "Spike"?

In log analysis, a "spike" is a sudden, sharp, and usually unexpected *increase* in the volume of a certain type of log.

  * **Normal:** You get 1 or 2 `http.response.status_code: 404` (Not Found) errors per minute. This is just "background noise."
  * **A Spike:** You suddenly get 5,000 `404` errors in one minute.

A spike is a *symptom* of a change. It is almost always the "smoke" that leads you to the "fire" (e.g., a service crash, a bad deployment, or a security attack).

### 2\. The Tool: The "Discover Histogram"

To find a spike, you must use the **Discover Histogram**.

  * **What is it?** It is the **bar chart** that automatically appears at the top of the Discover page. You do not need to create it. It is a core part of the Kibana interface.
  * **When does it appear?** It appears as soon as you select an index pattern (like `access-logs*`) and a time range that contains data.
  * **What does it show?**
      * The **`x-axis` (horizontal)** is **Time** (your selected time range).
      * The **`y-axis` (vertical)** is the **Count** of logs.

This histogram is your "spike detector." It is not static; it is **dynamic**. It will instantly redraw itself to show the results of any query you type in the KQL search bar.

**This is the most important concept:**

  * **With no query:** The histogram shows the count of *all* logs over time.
  * **With a query like `http.response.status_code: 500`:** The histogram *instantly* changes to show the count of *only* `500` error logs over time.

This allows you to visually pinpoint the exact moment an error spike occurred.

### 3\. Hands-On Lab: Using the Histogram to Find a Spike

**Prerequisite:**

1.  Navigate to **Discover** (☰ -\> Analytics -\> Discover).
2.  Select your **`access-logs*`** index pattern.
3.  Set your **Time Picker** to the absolute range of your 2020 sample data (e.g., `Jan 1, 2020` to `Apr 1, 2020`).
4.  You will now see the **Histogram** at the top of the page, showing the total volume of all your logs.

#### 🚀 Lab 1: Isolate an Error Spike

**Task:** We want to stop looking at *all* traffic and see the timeline of *only* server errors.

1.  **Action:** In the KQL search bar (the main search bar at the top), type:
    `http.response.status_code: 5*`
2.  Press **Enter**.
3.  **Analyze:** Look at the **Histogram**. It has now changed. It is no longer showing thousands of logs. It now shows a much smaller chart with "spikes" (bars) *only* at the specific times when `5xx` errors occurred. You have visually isolated the failure timeline.

#### 🚀 Lab 2: Correlate Spikes for Root Cause Analysis

**Task:** We suspect failures in the `payment-service` might be causing errors on the `frontend-web`. Let's see if their error spikes are related.

1.  **Action:** In the KQL search bar, enter this query to show errors from *both* services:
    ```kql
    (service_name: "payment-service" and http.response.status_code: 5*) or (service_name: "frontend-web" and http.response.status_code: 404)
    ```
2.  **Analyze:** The **Histogram** updates again. It now shows a combined timeline of `payment-service` server errors *and* `frontend-web` "not found" errors.
3.  Look for patterns. If you see a bar for the `payment-service` (e.g., at 11:01) and it is immediately followed by a bar for the `frontend-web` (e.g., at 11:02), you have established a strong visual correlation that one is causing the other.

#### 🚀 Lab 3: Zoom in on a Spike for Context

**Task:** We've seen the spike. Now, what *else* happened at that exact time?

1.  **Action:** In the KQL bar, **clear your query** and press Enter. The histogram will update to show *all* log traffic again.
2.  **Action:** On the **Histogram**, find the time of the spike you just identified (e.g., `11:01:00`).
3.  **Action:** **Click and drag your mouse** on the histogram to select a small window *around* that spike (e.g., from `11:00:00` to `11:05:00`).
4.  **Analyze:** The **Time Picker** and **Document Table** will update to this new, 5-minute time range. You can now see the full sequence of *all* logs (not just errors) that led up to and followed the failure. This "neighbor analysis" is essential for debugging.