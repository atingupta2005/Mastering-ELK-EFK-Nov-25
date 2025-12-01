# Day 11 – Hands-On Fluentd (Elasticsearch 9.x | CentOS)

---

## 1. Install Fluentd (Basic Setup – Latest Method)

Fluentd is installed using the officially maintained **fluent‑package** on CentOS.

### Step 1 – Install Fluentd Package

```bash
curl -fsSL https://fluentd.cdn.cncf.io/sh/install-redhat-fluent-package6-lts.sh | sh
```

This command:

* Installs Fluentd
* Creates the Fluentd service
* Sets up default directories

---

### Step 2 – Start and Enable Fluentd Service

```bash
sudo systemctl start fluentd.service
sudo systemctl enable fluentd.service
```

---

### Step 3 – Verify Fluentd Service

```bash
sudo systemctl status fluentd.service
```

Service should show **active (running)**.

---

### Important Paths After Installation

* Main configuration file:

  ```text
  /etc/fluent/fluentd.conf
  ```
* Fluentd log file:

  ```text
  /var/log/fluent/fluentd.log
  ```

---

## 2. Configure Fluentd Input for Logs

In this lab, Fluentd will read logs from a simple application log file.

---

### Step 1 – Create a Sample Log File

```bash
sudo mkdir -p /var/log/myapp
sudo touch /var/log/myapp/app.log
```

Add sample log entries:

```bash
echo "INFO Application started" | sudo tee -a /var/log/myapp/app.log
echo "ERROR Database connection failed" | sudo tee -a /var/log/myapp/app.log
echo "INFO User login successful" | sudo tee -a /var/log/myapp/app.log
```

---

### Step 2 – Open Fluentd Configuration File

```bash
sudo vi /etc/fluent/fluentd.conf
```

---

### Step 3 – Add Input Configuration

Add the following at the end of the file:

```conf
<source>
  @type tail
  path /var/log/myapp/app.log
  pos_file /var/log/fluentd/app.log.pos
  tag myapp.logs
  format none
</source>
```

Explanation (simple):

* `@type tail` → Reads a file continuously
* `path` → Log file location
* `pos_file` → Stores last read position
* `tag` → Label for routing logs
* `format none` → Reads raw log lines

---

## 3. Configure Fluentd Output to Elasticsearch

Now Fluentd will send collected logs to Elasticsearch.

---

### Step 1 – Install Elasticsearch Output Plugin

```bash
sudo /opt/fluent/bin/fluent-gem install fluent-plugin-elasticsearch
```

---

### Step 2 – Add Elasticsearch Output Configuration

Add this block below the input section:

```conf
<match myapp.logs>
  @type elasticsearch
  host localhost
  port 9200
  index_name fluentd-logs
  logstash_format true
</match>
```

Explanation:

* `@type elasticsearch` → Output to Elasticsearch
* `host` and `port` → Elasticsearch address
* `index_name` → Index where logs will be stored
* `logstash_format` → Adds date to index name

---

### Step 3 – Restart Fluentd

```bash
sudo systemctl restart fluentd.service
```

---

## 4. Validate Logs in Elasticsearch

### Step 1 – Check Index Creation

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/indices?v"
```

You should see an index similar to:

```text
fluentd-logs-YYYY.MM.DD
```

---

### Step 2 – Search Logs in the Index

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/fluentd-logs*/_search?pretty"
```

Verify that log messages from `app.log` appear in the output.

---

## 5. Validate Logs in Kibana

### Step 1 – Create Index Pattern

* Open Kibana in the browser
* Go to **Stack Management → Index Patterns**
* Create index pattern: `fluentd-logs*`
* Select a time field if available

---

### Step 2 – View Logs in Discover

* Open **Discover**
* Select index pattern `fluentd-logs*`
* Verify sample log messages are visible

---

## 6. Compare Fluentd Pipeline with Logstash Pipeline

### Fluentd Pipeline (Basic)

```
Log File → Fluentd (Input + Output) → Elasticsearch → Kibana
```

### Logstash Pipeline (Basic)

```
Log File → Logstash Input → Logstash Filter → Logstash Output → Elasticsearch → Kibana
```

### Simple Difference

* Fluentd is **lighter and faster for simple log forwarding**
* Logstash is **used when complex filtering and parsing is required**

---

## 7. Common Checks and Troubleshooting (Basic)

Check Fluentd service:

```bash
sudo systemctl status fluentd.service
```

Check Fluentd logs:

```bash
sudo tail -f /var/log/fluent/fluentd.log
```

If data is not visible in Elasticsearch:

* Verify `fluentd.conf` for syntax errors
* Confirm Elasticsearch is running on port 9200
* Restart Fluentd after every change

---
