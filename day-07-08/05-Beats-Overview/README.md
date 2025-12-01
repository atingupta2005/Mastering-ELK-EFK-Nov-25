# Beats Overview (Beginner to Intermediate Guide for Elastic Stack 9.x)

# 8. What Are Beats? (Lightweight Data Shippers)

**Beats** are a family of **lightweight, single‑purpose data shippers** created by Elastic. They collect data from your servers, applications, or systems and forward it to **Elasticsearch** or **Logstash**.

### Key Characteristics

* Small, efficient binaries written in Go
* Zero dependencies
* Low CPU and memory usage
* Purpose-specific (each Beat solves a different problem)
* Often run directly on your servers or containers

### Why Beats Instead of Logstash?

Beats are preferred at edge/host level because:

* They are lightweight (low resource usage)
* Require no JVM
* Can handle log rotation safely
* Provide reliability using **file harvesting** and **backpressure handling**

---

# 9. Filebeat – Overview & Use Cases

Filebeat is used to **collect and ship log files**. It reads log files line by line, detects changes, handles rotations, and forwards logs efficiently.

## How Filebeat Works (Internal Architecture)

```
Log file → Harvester → Spooler → Output (ES / Logstash)
```

### 1. Harvesting

Harvesting is the process where Filebeat reads each file line-by-line.

* One harvester per file
* Tracks file offset
* Detects rotations
* Avoids re-reading logs

### 2. Spooler

The spooler buffers log lines into batches before sending.

* Controls throughput
* Reduces network load
* Works with backpressure

### 3. Backpressure Handling

If Elasticsearch or Logstash slows down, Filebeat applies **backpressure**:

* Pauses sending new batches
* Continues tracking file positions
* Prevents data loss and overload

This makes Filebeat highly reliable.

## Use Cases

* Application logs
* Web server logs (Apache/Nginx)
* System logs
* Docker/Kubernetes logs

## Example Input

```
filebeat.inputs:
  - type: log
    paths:
      - /var/log/nginx/access.log
```

## Output to Logstash

```
output.logstash:
  hosts: ["localhost:5044"]
```

## Output to Elasticsearch

Supports both HTTP and HTTPS.

```
output.elasticsearch:
  hosts: ["http://localhost:9200"]
```

## Passing Credentials

```
output.elasticsearch:
  hosts: ["http://localhost:9200"]
  username: "elastic"
  password: "StrongPassword"
```

Or with API key:

```
api_key: "BASE64_KEY"
```

# 10. Metricbeat – Overview & Use Cases

Metricbeat – Overview & Use Cases
Metricbeat collects **metrics and statistics** from systems and services.

It does NOT ship logs — instead, it ships **numbers, counters, and performance data**.

## What Metricbeat Can Monitor

### ✓ Operating System Metrics

* CPU usage
* Memory usage
* Disk I/O
* Network I/O

### ✓ Service Metrics

Metricbeat modules include integrations for:

* MySQL
* PostgreSQL
* Redis
* Kafka
* Nginx
* Apache
* Docker
* Kubernetes
* Elasticsearch
* Logstash
* Systemd

### Why Use Metricbeat?

* Real-time system performance visibility
* Automatic dashboards provided by Elastic
* Helps in monitoring server health
* Useful for SREs & DevOps

## Example: Collect System Metrics

```
metricbeat.modules:
  - module: system
    metricsets: ["cpu", "load", "memory", "network"]
    period: 10s
```

## Example: Collect Nginx Metrics

```
metricbeat.modules:
  - module: nginx
    metricsets: ["stubstatus"]
    hosts: ["http://localhost:8080"]
```

## Example Output to Elasticsearch

```
output.elasticsearch:
  hosts: ["http://localhost:9200"]
```

---

# 11. How Beats Send Data to Elasticsearch/Logstash

Beats use a **built-in output module** to send events.
Data transmission is:

* Secure (TLS supported)
* Reliable (automatic retries)
* Backpressure‑aware

## Two Possible Paths

```
Beats → Elasticsearch
Beats → Logstash → Elasticsearch
```

## When to Send Directly to Elasticsearch

* Logs are clean and structured
* Only minimal parsing needed
* Want minimal latency

Example:

```
output.elasticsearch:
  hosts: ["http://es01:9200"]
```

## When to Use Logstash

* Logs need parsing (grok, mutate, date)
* Logs need routing/forking
* Need custom fields
* Want to enrich logs before indexing

Example:

```
output.logstash:
  hosts: ["logstash01:5044"]
```

## Protocol Used

Beats communicate over the **Beats protocol** using TCP.

* Default Logstash input: `beats { port => 5044 }`
* Supports TLS encryption

---

# 12. Basic Filebeat Installation

Here is the simplest installation process for Filebeat.

## Step 1: Download Filebeat (Example: 9.x)

### Debian/Ubuntu

```
wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-9.2.1-amd64.deb
sudo dpkg -i filebeat-9.2.1-amd64.deb
```

### RHEL/CentOS

```
wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-9.2.1-x86_64.rpm
sudo rpm -ivh filebeat-9.2.1-x86_64.rpm
```

---

## Step 2: Enable a Simple Log Input

```
filebeat.inputs:
  - type: log
    paths:
      - /var/log/syslog
```

---

## Step 3: Choose Output

### Send to Elasticsearch

```
output.elasticsearch:
  hosts: ["http://localhost:9200"]
```

### Send to Logstash

```
output.logstash:
  hosts: ["localhost:5044"]
```

---

## Step 4: Start Filebeat

```
sudo systemctl start filebeat
sudo systemctl enable filebeat
```

---

## Step 5: Verify Filebeat Is Working

### Check service status

```
sudo systemctl status filebeat
```

### Check logs

```
sudo tail -f /var/log/filebeat/filebeat
```

### Check indices in Elasticsearch

```
curl http://localhost:9200/_cat/indices?v
```

---

---

# 13. Important Internal Concepts in Beats (Backpressure, Harvesting, Spooler)

This section explains the internal mechanisms that make Beats reliable and efficient.

## 13.1 Backpressure Handling

Backpressure occurs when the output (Elasticsearch or Logstash) becomes slow or overloaded.

Beats automatically detects this and **slows down** sending data to avoid overwhelming the destination.

### How Backpressure Works

* Beats sends data in batches.
* If Elasticsearch/Logstash responds slowly or rejects requests, Beats **pauses** sending more data.
* Harvesters continue reading logs but buffer data until the output recovers.

### Example Scenario

If Elasticsearch is overloaded:

* Filebeat stops pushing new batches
* Harvester continues watching files
* Registrar tracks offsets
* No logs are lost

This behaviour prevents:

* Data loss
* Server overload
* Uncontrolled retries

---

## 13.2 Harvesting

Harvesting is the process by which Filebeat **reads log files line-by-line**.

### Key Responsibilities

* Read new lines appended to a file
* Detect when a file is rotated
* Avoid re-reading old lines

### Example Flow

```
/var/log/app.log → Harvester → Spooler → Output
```

### Multiple Harvesters

If Filebeat monitors 10 log files, it may launch 10 harvesters (one per file).

Each harvester manages:

* File pointer position
* Newline detection
* State management

---

## 13.3 Spooler (Event Buffer)

The spooler collects events from harvesters and groups them into batches.

### Why Spooler Exists

* Improves performance
* Reduces network calls
* Enables backpressure handling

### Flow

```
Harvester → Spooler (batch N events) → Output
```

### Example

If spool size is 2048:

* Filebeat collects up to 2048 log lines
* Sends them as a batch to Elasticsearch/Logstash

This approach reduces overhead and increases throughput.

---

# 14. Can Beats Work with Non-HTTPS Elasticsearch?

Yes. Beats can send data to **HTTP** or **HTTPS**.

### Example: Using HTTP (Not Secure)

```
output.elasticsearch:
  hosts: ["http://localhost:9200"]
```

### Example: Using HTTPS (Secure)

```
output.elasticsearch:
  hosts: ["https://es01.mydomain.com:9200"]
  ssl.certificate_authorities: ["/etc/filebeat/certs/ca.crt"]
```

For production, HTTPS is strongly recommended.

---

# 15. How to Pass User Credentials to Elasticsearch

Beats supports:

* Username/password authentication
* API key authentication

## 15.1 Username & Password

```
output.elasticsearch:
  hosts: ["http://localhost:9200"]
  username: "elastic"
  password: "MyStrongPassword"
```

## 15.2 API Key (More Secure)

```
output.elasticsearch:
  hosts: ["http://localhost:9200"]
  api_key: "BASE64_API_KEY"
```

API keys are preferred because:

* No need to expose user credentials
* Permissions can be restricted

---

# 16. Important Configuration File Paths

Below are the standard paths for Filebeat (Linux package installations).

### 16.1 Main Configuration

```
/etc/filebeat/filebeat.yml
```

This is where you define:

* inputs
* modules
* outputs
* processors

### 16.2 Filebeat Modules Directory

```
/etc/filebeat/modules.d/
```

Each `.yml` file inside represents a module such as:

* system
* nginx
* apache
* mysql

Enable a module:

```
sudo filebeat modules enable nginx
```

### 16.3 Filebeat Logs

```
/var/log/filebeat/filebeat
```

Used for troubleshooting and verifying ingestion.

### 16.4 Filebeat Binary

```
/usr/bin/filebeat
```

Run directly for debugging:

```
filebeat -e
```

### 16.5 Registry File (State Tracking)

```
/var/lib/filebeat/registry/filebeat/
```

This contains:

* file offsets
* inode tracking
* state information

This ensures logs are **not duplicated** even after restart.
