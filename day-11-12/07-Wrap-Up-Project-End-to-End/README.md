# End-to-End ELK Stack Project

> **Project Duration:** 2 hours  
> **Prerequisites:** ELK stack running (docker-elk), default credentials: `elastic:changeme`

---

## Project Overview

Build a complete centralized logging system for a web application using the ELK stack. You will:

1. **Collect logs** using Filebeat
2. **Parse logs** using Logstash with GROK
3. **Visualize data** in Kibana dashboards
4. **Configure security** with users and roles
5. **Monitor** the cluster health

---

## Part 1: Data Ingestion & Processing (45 minutes)

### Step 1: Create Sample Apache Logs (5 minutes)

**If you don't have Apache logs, create sample logs:**

```bash
# Create sample log file
sudo mkdir -p /var/log/httpd
sudo tee /var/log/httpd/access_log << 'EOF'
127.0.0.1 - - [15/Jan/2025:10:00:01 +0000] "GET /index.html HTTP/1.1" 200 1234 "-" "Mozilla/5.0"
192.168.1.10 - - [15/Jan/2025:10:00:02 +0000] "GET /about.html HTTP/1.1" 200 2345 "-" "Mozilla/5.0"
10.0.0.5 - - [15/Jan/2025:10:00:03 +0000] "GET /contact.html HTTP/1.1" 404 567 "-" "Chrome/91.0"
127.0.0.1 - - [15/Jan/2025:10:00:04 +0000] "POST /login HTTP/1.1" 200 890 "-" "Firefox/89.0"
192.168.1.10 - - [15/Jan/2025:10:00:05 +0000] "GET /products.html HTTP/1.1" 200 3456 "-" "Mozilla/5.0"
10.0.0.5 - - [15/Jan/2025:10:00:06 +0000] "GET /index.html HTTP/1.1" 200 1234 "-" "Chrome/91.0"
127.0.0.1 - - [15/Jan/2025:10:00:07 +0000] "GET /admin.html HTTP/1.1" 403 234 "-" "Mozilla/5.0"
192.168.1.10 - - [15/Jan/2025:10:00:08 +0000] "GET /index.html HTTP/1.1" 200 1234 "-" "Safari/14.0"
EOF

# Set permissions
sudo chmod 644 /var/log/httpd/access_log
```

**Command explanation:**
* Creates sample Apache access logs in standard format
* **Purpose:** Provide test data for the project

---

### Step 2: Configure Filebeat (10 minutes)

**Create Filebeat configuration:**

```bash
sudo tee /etc/filebeat/filebeat.yml << 'EOF'
filebeat.inputs:
  - type: log
    enabled: true
    paths:
      - /var/log/httpd/access_log
    fields:
      log_type: apache_access
    fields_under_root: true

output.logstash:
  hosts: ["localhost:5044"]

logging.level: info
EOF
```

**Command explanation:**
* `filebeat.inputs`: Define log sources
* `paths`: Log file locations
* `fields`: Add custom metadata
* `output.logstash`: Send to Logstash on port 5044
* **Purpose:** Configure Filebeat to collect Apache logs and send to Logstash

**Test Filebeat configuration:**

```bash
sudo filebeat test config
```

**Command explanation:**
* Validates configuration file syntax
* **Purpose:** Ensure configuration is correct before starting

**Start Filebeat:**

```bash
sudo systemctl start filebeat
sudo systemctl enable filebeat
sudo systemctl status filebeat
```

**Command explanation:**
* `start`: Start Filebeat service
* `enable`: Start automatically on boot
* `status`: Verify service is running
* **Purpose:** Start Filebeat and verify it's working

**Verify Filebeat is running:**

```bash
sudo systemctl status filebeat | grep "active (running)"
```

**Expected output:** Should show "active (running)"

---

### Step 3: Configure Logstash Pipeline (20 minutes)

**Navigate to docker-elk directory:**

```bash
cd ~/docker-elk
```

**Create Logstash pipeline configuration:**

```bash
cat > logstash/pipeline/apache-logs.conf << 'EOF'
input {
  beats {
    port => 5044
  }
}

filter {
  if [log_type] == "apache_access" {
    grok {
      match => { "message" => "%{COMBINEDAPACHELOG}" }
    }
    date {
      match => [ "timestamp", "dd/MMM/yyyy:HH:mm:ss Z" ]
    }
    mutate {
      convert => {
        "response" => "integer"
        "bytes" => "integer"
      }
    }
  }
}

output {
  elasticsearch {
    hosts => ["http://elasticsearch:9200"]
    user => "logstash_internal"
    password => "${LOGSTASH_INTERNAL_PASSWORD}"
    index => "apache-logs-%{+YYYY.MM.dd}"
  }
}
EOF
```

**Command explanation:**
* `input { beats }`: Receive data from Filebeat on port 5044
* `filter { grok }`: Parse Apache logs using pre-built pattern `%{COMBINEDAPACHELOG}`
* `date`: Parse timestamp field
* `mutate`: Convert fields to proper data types
* `output { elasticsearch }`: Send parsed data to Elasticsearch
* `index => "apache-logs-%{+YYYY.MM.dd}"`: Create daily indices
* **Purpose:** Parse Apache logs and send to Elasticsearch

**Restart Logstash:**

```bash
docker compose restart logstash
```

**Command explanation:**
* Restarts Logstash to load new pipeline configuration
* **Purpose:** Apply configuration changes

**Check Logstash logs:**

```bash
docker compose logs -f logstash
```

**Command explanation:**
* `-f`: Follow log output
* **Purpose:** Verify Logstash is processing data correctly
* **Look for:** "Pipeline started successfully" and no errors

**Wait 30 seconds, then check if data is being indexed:**

```bash
curl -u elastic:changeme "http://localhost:9200/_cat/indices/apache-logs-*?v"
```

**Command explanation:**
* Lists indices matching pattern `apache-logs-*`
* **Purpose:** Verify indices are being created
* **Expected:** Should see index like `apache-logs-2025.01.15`

---

### Step 4: Verify Data in Elasticsearch (10 minutes)

**Check if documents are indexed:**

```bash
curl -u elastic:changeme "http://localhost:9200/apache-logs-*/_count?pretty"
```

**Command explanation:**
* `_count`: Count documents in indices
* **Purpose:** Verify documents are being indexed
* **Expected:** Should show count > 0

**View a sample document:**

```bash
curl -u elastic:changeme "http://localhost:9200/apache-logs-*/_search?size=1&pretty"
```

**Command explanation:**
* `_search`: Search API
* `size=1`: Return only 1 document
* **Purpose:** See actual document structure and verify GROK parsing worked

**Verify parsed fields:**

```bash
curl -u elastic:changeme "http://localhost:9200/apache-logs-*/_search?pretty" \
  -H "Content-Type: application/json" \
  -d '{
    "size": 1,
    "_source": ["clientip", "verb", "request", "response", "bytes", "timestamp"]
  }'
```

**Command explanation:**
* `_source`: Specify which fields to return
* **Purpose:** Verify GROK extracted fields correctly
* **Expected fields:** `clientip`, `verb`, `request`, `response`, `bytes`, `timestamp`

**If no data appears:**
* Check Filebeat status: `sudo systemctl status filebeat`
* Check Logstash logs: `docker compose logs logstash | tail -20`
* Verify log file exists: `ls -l /var/log/httpd/access_log`

---

## Part 2: Visualization in Kibana (30 minutes)

### Step 5: Create Index Pattern (5 minutes)

**Access Kibana:**

1. Open browser: `http://localhost:5601`
2. Login with: `elastic` / `changeme`

**Create Index Pattern:**

1. Click **☰ (hamburger menu)** → **Analytics** → **Discover**
2. Click **"Create index pattern"** or **"Add data"**
3. **Index pattern name:** Enter `apache-logs-*`
4. Click **"Next step"**
5. **Time field:** Select `@timestamp` from dropdown
6. Click **"Create index pattern"**

**Command explanation:**
* Index pattern tells Kibana which indices to search
* `apache-logs-*` matches all daily indices
* `@timestamp` is used for time-based filtering
* **Purpose:** Enable Kibana to search and visualize your data

**Verify fields are detected:**

1. After creating pattern, you should see field list
2. Look for: `clientip`, `verb`, `request`, `response`, `bytes`
3. These are fields extracted by GROK

---

### Step 6: Create Visualizations (15 minutes)

**Visualization 1: Status Code Bar Chart (5 minutes)**

1. Click **☰** → **Analytics** → **Visualize Library**
2. Click **"Create visualization"**
3. Select **"Vertical Bar"** chart
4. **Data source:** Select `apache-logs-*` index pattern
5. **Metrics:**
   - Y-axis: **Count**
6. **Buckets:**
   - X-axis: **Terms**
   - Field: `response.keyword`
   - Size: `10`
   - Order: **Descending**
7. Click **"Update"** to see chart
8. Click **"Save"** → Name: `Apache Status Codes`

**Command explanation:**
* Bar chart shows distribution of HTTP status codes
* **Purpose:** Identify most common status codes (200, 404, 403, etc.)

---

**Visualization 2: Top Client IPs Pie Chart (5 minutes)**

1. Click **"Create visualization"**
2. Select **"Pie"** chart
3. **Data source:** Select `apache-logs-*` index pattern
4. **Metrics:**
   - Slice size: **Count**
5. **Buckets:**
   - Slice by: **Terms**
   - Field: `clientip.keyword`
   - Size: `5`
6. Click **"Update"** to see chart
7. Click **"Save"** → Name: `Top Client IPs`

**Command explanation:**
* Pie chart shows which IP addresses are making most requests
* **Purpose:** Identify top clients accessing the web server

---

**Visualization 3: Recent Logs Data Table (5 minutes)**

1. Click **"Create visualization"**
2. Select **"Data Table"**
3. **Data source:** Select `apache-logs-*` index pattern
4. **Metrics:**
   - Metric: **Count**
5. **Buckets:**
   - Split rows: **Terms**
   - Field: `request.keyword`
   - Size: `10`
   - Order: **Descending**
6. Click **"Update"** to see table
7. Click **"Save"** → Name: `Top Requests`

**Command explanation:**
* Data table shows most requested URLs
* **Purpose:** See which pages are accessed most frequently

---

### Step 7: Create Dashboard (10 minutes)

**Create Dashboard:**

1. Click **☰** → **Analytics** → **Dashboard**
2. Click **"Create dashboard"**
3. Click **"Add"** → **"Add an existing"**
4. Add all three visualizations:
   - Apache Status Codes
   - Top Client IPs
   - Top Requests
5. Arrange visualizations on dashboard
6. Click **"Save"** → Name: `Apache Logs Dashboard`

**Configure Auto-refresh:**

1. Click **"Auto-refresh"** dropdown (top right)
2. Select **"5 seconds"** or **"1 minute"**
3. Dashboard will automatically update

**Command explanation:**
* Dashboard combines multiple visualizations
* Auto-refresh keeps data current
* **Purpose:** Single view of all key metrics

**Take Screenshot:**
* Save screenshot of dashboard for deliverables

---

## Part 3: Security & Monitoring (45 minutes)

### Step 8: Security Configuration (20 minutes)

**Verify Security is Enabled:**

```bash
curl -u elastic:changeme "http://localhost:9200/_cluster/settings?include_defaults=true&filter_path=**.xpack.security.enabled&pretty"
```

**Command explanation:**
* Checks if security is enabled
* **Purpose:** Verify security features are active

**Create Custom Role:**

```bash
curl -u elastic:changeme -X PUT "http://localhost:9200/_security/role/logs_viewer" \
  -H "Content-Type: application/json" \
  -d '{
    "indices": [
      {
        "names": ["apache-logs-*"],
        "privileges": ["read"]
      }
    ]
  }'
```

**Command explanation:**
* `PUT _security/role/logs_viewer`: Create new role
* `"names": ["apache-logs-*"]`: Role can access apache-logs indices
* `"privileges": ["read"]`: Only read permission (cannot write or delete)
* **Purpose:** Create role with limited permissions (principle of least privilege)

**Create Custom User:**

```bash
curl -u elastic:changeme -X POST "http://localhost:9200/_security/user/logs_user" \
  -H "Content-Type: application/json" \
  -d '{
    "password": "student123",
    "roles": ["logs_viewer"]
  }'
```

**Command explanation:**
* `POST _security/user/logs_user`: Create new user
* `"password"`: User's password
* `"roles": ["logs_viewer"]`: Assign role to user
* **Purpose:** Create user with restricted access

**Test User Access:**

```bash
# Test login with new user
curl -u logs_user:student123 "http://localhost:9200/apache-logs-*/_search?size=1&pretty"
```

**Command explanation:**
* Uses new user credentials
* **Purpose:** Verify user can access apache-logs indices

**Test Access Denied (should fail):**

```bash
# Try to access other indices (should fail)
curl -u logs_user:student123 "http://localhost:9200/_cat/indices?pretty"
```

**Command explanation:**
* User should NOT be able to see all indices
* **Purpose:** Verify access control is working

**Login to Kibana with New User:**

1. Logout from Kibana (if logged in)
2. Login with: `logs_user` / `student123`
3. You should only see `apache-logs-*` indices
4. Verify dashboard is accessible

---

### Step 9: Monitoring (15 minutes)

**Check Cluster Health:**

```bash
curl -u elastic:changeme "http://localhost:9200/_cluster/health?pretty"
```

**Command explanation:**
* Shows overall cluster status
* **Purpose:** Verify cluster is healthy (green or yellow)

**List All Indices:**

```bash
curl -u elastic:changeme "http://localhost:9200/_cat/indices?v"
```

**Command explanation:**
* Lists all indices with key metrics
* **Purpose:** See all indices and their sizes

**Check Disk Usage:**

```bash
curl -u elastic:changeme "http://localhost:9200/_cat/allocation?v"
```

**Command explanation:**
* Shows disk usage per node
* **Purpose:** Monitor disk space usage

**Check Index Sizes:**

```bash
curl -u elastic:changeme "http://localhost:9200/_cat/indices/apache-logs-*?v&h=index,docs.count,store.size"
```

**Command explanation:**
* Shows document count and size for apache-logs indices
* **Purpose:** Monitor data growth

**Check Node Stats:**

```bash
curl -u elastic:changeme "http://localhost:9200/_cat/nodes?v&h=name,heap.percent,ram.percent,cpu"
```

**Command explanation:**
* Shows node resource usage
* **Purpose:** Monitor CPU, memory usage

---

### Step 10: Maintenance (10 minutes)

**Clear Cache:**

```bash
curl -u elastic:changeme -X POST "http://localhost:9200/_cache/clear"
```

**Command explanation:**
* Clears all caches
* **Purpose:** Free up memory

**Check Logstash Pipeline Status:**

```bash
curl "http://localhost:9600/_node/pipelines?pretty"
```

**Command explanation:**
* Shows Logstash pipeline status
* **Purpose:** Verify Logstash is processing data

**View Logstash Logs:**

```bash
docker compose logs logstash | tail -20
```

**Command explanation:**
* Shows recent Logstash logs
* **Purpose:** Check for errors or warnings

**Check Filebeat Status:**

```bash
sudo systemctl status filebeat
```

**Command explanation:**
* Shows Filebeat service status
* **Purpose:** Verify Filebeat is running

---

## Deliverables Checklist

Complete the following and document:

- [ ] **Filebeat configuration** (`/etc/filebeat/filebeat.yml`)
- [ ] **Logstash pipeline** (`logstash/pipeline/apache-logs.conf`)
- [ ] **At least 2 Kibana visualizations created**
- [ ] **1 Kibana dashboard created**
- [ ] **1 custom role created** (`logs_viewer`)
- [ ] **1 custom user created** (`logs_user`)
- [ ] **Cluster health check** (status: green/yellow)
- [ ] **Screenshot of dashboard** (save for submission)

---

## Troubleshooting Guide

### Problem: Filebeat not sending data

**Solution:**
```bash
# Check Filebeat status
sudo systemctl status filebeat

# Check Filebeat logs
sudo journalctl -u filebeat -n 50

# Restart Filebeat
sudo systemctl restart filebeat
```

---

### Problem: Logstash not receiving data

**Solution:**
```bash
# Check Logstash logs
docker compose logs logstash | tail -50

# Check if port 5044 is listening
netstat -tlnp | grep 5044

# Restart Logstash
docker compose restart logstash
```

---

### Problem: No data in Elasticsearch

**Solution:**
```bash
# Check if indices exist
curl -u elastic:changeme "http://localhost:9200/_cat/indices/apache-logs-*?v"

# Check document count
curl -u elastic:changeme "http://localhost:9200/apache-logs-*/_count?pretty"

# Verify log file has data
cat /var/log/httpd/access_log
```

---

### Problem: GROK parsing not working

**Solution:**
```bash
# Check Logstash logs for GROK errors
docker compose logs logstash | grep -i grok

# Test GROK pattern online: https://grokdebug.herokuapp.com/
# Or view a sample document to see what fields were extracted
curl -u elastic:changeme "http://localhost:9200/apache-logs-*/_search?size=1&pretty"
```

---

### Problem: Cannot create index pattern in Kibana

**Solution:**
1. Verify indices exist: `curl -u elastic:changeme "http://localhost:9200/_cat/indices/apache-logs-*?v"`
2. Wait a few seconds after data is indexed
3. Refresh Kibana page
4. Try creating pattern again

---

### Problem: User cannot access Kibana

**Solution:**
```bash
# Verify user exists
curl -u elastic:changeme "http://localhost:9200/_security/user/logs_user?pretty"

# Verify role is assigned
curl -u elastic:changeme "http://localhost:9200/_security/user/logs_user?pretty" | grep roles

# Test user can access Elasticsearch
curl -u logs_user:student123 "http://localhost:9200/apache-logs-*/_search?size=1&pretty"
```

---

## Quick Reference Commands

**Filebeat:**
```bash
sudo systemctl status filebeat
sudo systemctl restart filebeat
sudo filebeat test config
```

**Logstash:**
```bash
docker compose restart logstash
docker compose logs -f logstash
curl "http://localhost:9600/_node/pipelines?pretty"
```

**Elasticsearch:**
```bash
curl -u elastic:changeme "http://localhost:9200/_cluster/health?pretty"
curl -u elastic:changeme "http://localhost:9200/_cat/indices?v"
curl -u elastic:changeme "http://localhost:9200/apache-logs-*/_search?size=1&pretty"
```

**Kibana:**
- URL: `http://localhost:5601`
- Default login: `elastic` / `changeme`

---

## Project Summary

**What You Built:**

1. ✅ **Data Collection:** Filebeat collects Apache logs
2. ✅ **Data Processing:** Logstash parses logs with GROK
3. ✅ **Data Storage:** Elasticsearch indexes parsed logs
4. ✅ **Data Visualization:** Kibana dashboards show insights
5. ✅ **Security:** Custom users and roles for access control
6. ✅ **Monitoring:** Cluster health and resource monitoring

---

**Congratulations!** You have successfully built an end-to-end ELK stack logging solution! 🎉

