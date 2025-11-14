## 📅 Day 8: Beats Overview

### 1\. What are Beats (Lightweight Shippers)? (Topic 8)

**Beats** are a family of **lightweight, special-purpose data shippers**. They are small, server-side agents, written in Go, that are designed to be installed on your source servers (e.g., web servers, database servers) to collect and "ship" data to a central location.

Their core design principle is to be "lightweight," meaning they use minimal CPU and memory. They are built to do *one job* and do it reliably.

The original Beats family included:

  * **Filebeat:** Collects logs from files.
  * **Metricbeat:** Collects system and service metrics.
  * **Packetbeat:** Monitors network packet data.
  * **Winlogbeat:** Collects Windows Event Logs.
  * **Auditbeat:** Collects Linux audit framework data.
  * **Heartbeat:** Monitors service uptime (like a `ping` tool).

-----

### The Evolution to Elastic Agent (A Critical 9.x Concept)

In modern Elastic Stack (versions 8.x and 9.x), the concept of "Beats" has evolved into the **Elastic Agent**.

  * **The Old Way (Beats):** To get logs *and* metrics from a server, you had to install and manage *two* separate agents: Filebeat and Metricbeat, each with its own configuration file.
  * **The New Way (Elastic Agent):** You install **one single agent** (the Elastic Agent) on each server. This single agent can do *everything*—collect logs, collect metrics, monitor uptime, and even provide endpoint security.

This new Elastic Agent is typically managed remotely by **Fleet**, a UI inside Kibana. You no longer edit local `.yml` files on each server. Instead, you create a central "policy" in Kibana (e.g., "Collect Nginx logs and System metrics"), and Fleet tells all 1,000 of your agents to apply that policy.

While "Filebeat" and "Metricbeat" still exist as standalone binaries (for advanced or legacy use cases), their *functionality* is now primarily consumed as part of the unified **Elastic Agent**.

-----

### 2\. Filebeat – Overview & Use Cases (Topic 9)

**Filebeat** is the most popular and widely used Beat. Its *only* job is to read lines from log files and send them to Elasticsearch or Logstash.

**Core Features:**

  * **Lightweight:** Has a very small resource footprint.
  * **Resilient:** It stores its "place" in a registry file. If the server or Filebeat restarts, it knows exactly where it left off, so no data is lost.
  * **Reliable:** Guarantees "at-least-once" delivery.
  * **Handles Log Rotation:** Automatically handles log files that are rotated, gzipped, and deleted.

**Common Use Cases:**

  * **Application Logs:** Tailing `my-app.log` from your custom applications.
  * **Web Server Logs:** Collecting `access.log` and `error.log` from Nginx, Apache, or IIS.
  * **System Logs:** Collecting system-level logs like `/var/log/syslog` or `/var/log/auth.log`.
  * **Database Logs:** Collecting slow query logs or error logs from MySQL, PostgreSQL, etc.

**Filebeat Modules:**
For common log types like Nginx, Filebeat has "modules." If you enable the `nginx` module, Filebeat will:

1.  Automatically know the default paths for Nginx logs.
2.  Know how to *parse* the Nginx log line, converting it from a string to structured JSON.
3.  Automatically ship a pre-built Kibana dashboard for visualizing Nginx logs.

-----

### 3\. Metricbeat – Overview & Use Cases (Topic 10)

**Metricbeat** is a lightweight shipper for **metrics** (time-series numerical data), not logs.

**Core Features:**

  * **Module-Based:** Metricbeat works using "modules" that know how to connect to and collect data from specific systems and services.
  * **Lightweight:** Designed to run on every server in your fleet to provide full-stack monitoring.
  * **Time-Series Optimized:** All data is pre-formatted with timestamps, host information, and metric types, ready for visualization in Kibana.

**Common Use Cases & Modules:**

  * **`system` Module (Most Common):**

      * **Use:** Collects core operating system metrics.
      * **Metrics:**
          * `cpu.usage` (user, system, idle)
          * `memory.used` / `memory.free`
          * `diskio.read_bytes` / `diskio.write_bytes`
          * `network.in_bytes` / `network.out_bytes`

  * **`docker` Module:**

      * **Use:** Connects to the Docker socket to collect metrics about all running containers.
      * **Metrics:** Container CPU usage, memory limits, network I/O.

  * **`nginx` Module:**

      * **Use:** Connects to the Nginx `stub_status` endpoint.
      * **Metrics:** `active_connections`, `accepts`, `handled`, `requests`.

  * **`elasticsearch` Module:**

      * **Use:** Monitors the health and performance of your Elasticsearch cluster itself.
      * **Metrics:** Cluster status, JVM heap usage, indexing rates, query latency.

-----

### 4\. How Beats Send Data to Elasticsearch/Logstash (Topic 11)

There are two primary architectural patterns for where Beats (or the Elastic Agent) send their data.

#### Path 1: Direct to Elasticsearch (The Simple, Modern Way)

This is the most common and recommended setup for most use cases.

`[Filebeat/Agent] ---> [Elasticsearch Cluster]`

  * **How it works:** The agent/beat is configured with the Elasticsearch `hosts` and API key. It uses a built-in "ingest pipeline" to parse and pre-process the data before indexing.
  * **Pros:**
      * Very simple, fewer moving parts.
      * Very fast.
      * The built-in "modules" (like the Nginx module) handle all parsing.
  * **Cons:**
      * Less flexible. If you have a custom, non-standard log format, the agent can't parse it.

#### Path 2: Via Logstash (The "Advanced" Way)

This setup is used when you need complex, server-side data transformation.

`[Filebeat/Agent] ---> [Logstash Server] ---> [Elasticsearch Cluster]`

  * **How it works:**
    1.  The Filebeat/Agent's output is *not* Elasticsearch. It is set to point to your Logstash server (e.g., `output.logstash.hosts: ["logstash-server:5044"]`).
    2.  The Logstash server is configured with a `beats` **input** plugin, listening on port `5044`.
    3.  Logstash runs its **filter** stage (e.g., `grok`, `mutate`, `date`, `enrich`) to perform heavy-duty parsing and transformation.
    4.  Logstash has an `elasticsearch` **output** plugin that sends the final, processed data to the cluster.
  * **Pros:**
      * Extremely powerful and flexible.
      * Can parse *any* data format.
      * Can enrich data (e.g., GeoIP, database lookups).
      * Can route data to multiple outputs (e.g., Elasticsearch and an S3 archive).
  * **Cons:**
      * More complex to manage (another service to maintain).
      * Slower, as it adds an extra "hop" for the data.

-----

### 5\. Basic Filebeat Installation (Standalone Method) (Topic 12)

This hands-on lab shows how to install and run **standalone Filebeat 9.x**. This is the "manual" or "legacy" method, where you configure the `.yml` file directly on the server.

**Prerequisite:** A CentOS 7/8/9 server and a running Elasticsearch cluster.

#### 🚀 Hands-On: Install and Run Filebeat

**Step 1: Install Filebeat**

```bash
# Import the Elastic GPG key
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch

# Add the Elastic 9.x repository (if not already done)
sudo vi /etc/yum.repos.d/elastic-9.x.repo
(Paste the `[elastic-9.x]` repo content)

# Install the filebeat package
sudo yum install filebeat
```

**Step 2: Configure `filebeat.yml`**
This is the main configuration file.

```bash
sudo vi /etc/filebeat/filebeat.yml
```

You need to configure two main sections:

**1. `filebeat.inputs` (Where to get data):**
Find this section. By default, it's disabled. Enable it and tell it to watch `/var/log/syslog`.

```yml
filebeat.inputs:
- type: filestream
  id: my-syslog-input
  enabled: true
  paths:
    - /var/log/messages
    - /var/log/syslog
```

  * **`type: filestream`**: This is the new, more powerful input ID (replacing the old `log` type).
  * **`paths`**: The log files you want to tail.

**2. `output.elasticsearch` (Where to send data):**
Find this section. Comment out the `output.logstash` section. Uncomment and edit the `output.elasticsearch` section.

```yml
# ---------------------------- Logstash Output -----------------------------
# output.logstash:
#   hosts: ["localhost:5044"]

# -------------------------- Elasticsearch Output --------------------------
output.elasticsearch:
  hosts: ["http://YOUR_ELASTICSEARCH_IP:9200"]
  
  # Use an API Key (Recommended for 9.x)
  # api_key: "id:secret"
  
  # Or, use username/password (Less Secure)
  # username: "elastic"
  # password: "YOUR_PASSWORD"
```

*Note: For a 9.x lab, the easiest way is to disable security in `elasticsearch.yml` (`xpack.security.enabled: false`) and just use the `hosts` line. For production, you *must* use `api_key` or `username/password`.*

**Step 3: Test Configuration**
Filebeat can check your `.yml` file for errors.

```bash
sudo filebeat test config -e
```

*If it says "Config OK", you are ready.*

**Step 4: Run Filebeat**

```bash
# Enable the service to start on boot
sudo systemctl enable filebeat

# Start the service now
sudo systemctl start filebeat
```

**Step 5: Verify in Kibana**

1.  Go to Kibana. It will take a minute for data to arrive.
2.  Filebeat auto-creates an index pattern named `filebeat-*`.
3.  Go to **Discover**.
4.  Switch your index pattern to **`filebeat-*`**.
5.  You should see your server's `/var/log/syslog` or `/var/log/messages` data flowing in.