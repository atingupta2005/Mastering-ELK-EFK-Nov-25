## 📅 Day 5: Log Analysis Basics - Spotting Spikes in Errors

### 1\. Conceptual Overview

Log analysis often begins by identifying anomalies in data volume. A "spike" is a sudden, significant increase in the count of a specific type of log, which typically indicates a meaningful event such- as a service failure, a security event, or a misconfiguration.

The primary tool for this analysis is the **Discover Histogram**. This bar chart displays the count of documents (y-axis) over your selected time range (x-axis).

This histogram is not static; it dynamically redraws itself to reflect the results of your KQL query and filters. By default, it shows the count of *all* logs. By applying a query (e.g., `http.response.status_code: 500`), you change the histogram to show the count of *only* `500` error logs. This allows you to visually pinpoint the exact time an error spike occurred.

### 2\. Hands-On Lab: Visual Analysis Workflow

**Prerequisite:**

  * Navigate to **Discover**.
  * Select the `access-logs*` index pattern.
  * Set your **Time Picker** to the absolute range of your 2020 sample data.

#### 🚀 Lab 1: Isolate an Error Spike

The first step is to change the histogram from showing "all traffic" to showing "only error traffic."

1.  **Action:** In the KQL search bar, enter the following query to find all server-side errors:
    `http.response.status_code: 5*`
2.  **Analyze:** Observe the **Histogram**. It has now updated. Instead of showing the total traffic volume, it now shows a timeline of *only* your `5xx` errors. You can visually identify the exact time and frequency of these failures.

#### 🚀 Lab 2: Correlate Spikes for Root Cause Analysis

Spikes are often related. A failure in a "backend" service can cause a spike of different errors in a "frontend" service.

1.  **Task:** We need to see if failures in the `payment-service` are correlated with errors on the `frontend-web`.
2.  **Action:** Enter a query to show errors from *both* services. This query finds all `5xx` errors from the payment service *OR* all `404` errors from the frontend.
    ```kql
    (service_name: "payment-service" and http.response.status_code: 5*) or (service_name: "frontend-web" and http.response.status_code: 404)
    ```
3.  **Analyze:** The histogram will now show the combined error spikes from both services. Observe the bars. If a spike for `payment-service` errors (which you can verify with a filter) is immediately followed by a spike in `frontend-web` errors, you have established a strong correlation and a likely root cause.

#### 🚀 Lab 3: Zoom in on a Spike for Context

After identifying a spike, the next step is to see what *else* happened at that exact moment.

1.  **Action:** In the KQL bar, **clear your query** and press Enter. The histogram will update to show *all* log traffic again.
2.  **Action:** On the histogram, find the time of the spike you identified in the previous lab (e.g., `11:01:00`).
3.  **Action:** Click and drag your mouse to select a small window *around* that spike (e.g., from `11:00:00` to `11:05:00`).
4.  **Analyze:** The **Time Picker** and **Document Table** will update to this new, 5-minute time range. You can now see the full sequence of *all* logs (not just errors) that led up to and followed the failure. This "neighbor analysis" is essential for debugging.