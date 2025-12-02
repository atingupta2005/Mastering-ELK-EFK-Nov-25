# Day 12 – Monitoring & Maintenance (Elasticsearch 9.x | CentOS)

---

## 1. Checking Elasticsearch Cluster Health

Cluster health shows the **overall working state of Elasticsearch**.

### 1.1 Basic Cluster Health Check

**Method 1: From host**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cluster/health?pretty"
```

**Command explanation:**
* `curl`: Command-line HTTP client
* `-u elastic:changeme`: Basic authentication
* `-X GET`: HTTP GET method
* `_cluster/health`: Cluster health API endpoint
* `?pretty`: Format JSON output for readability
* **Purpose:** Check overall cluster health status

---

### 1.2 Understanding Health Status

**Response example:**
```json
{
  "cluster_name" : "docker-cluster",
  "status" : "green",
  "timed_out" : false,
  "number_of_nodes" : 1,
  "number_of_data_nodes" : 1,
  "active_primary_shards" : 5,
  "active_shards" : 5,
  "relocating_shards" : 0,
  "initializing_shards" : 0,
  "unassigned_shards" : 0,
  "delayed_unassigned_shards" : 0,
  "number_of_pending_tasks" : 0,
  "number_of_in_flight_fetch" : 0,
  "task_max_waiting_in_queue_millis" : 0,
  "active_shards_percent_as_number" : 100.0
}
```

**Status values:**

* **green** → All primary and replica shards are working
  * **Meaning:** Cluster is fully operational
  * **Action:** No action needed

* **yellow** → All primary shards are working, some replicas missing
  * **Meaning:** Data is safe, but redundancy is reduced
  * **Action:** Acceptable for single-node setups, add nodes for redundancy

* **red** → Some primary shards are not working (data risk)
  * **Meaning:** Data may be lost or inaccessible
  * **Action:** Immediate attention required

---

### 1.3 Wait for Specific Health Status

Wait for cluster to become green:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cluster/health?wait_for_status=green&timeout=30s&pretty"
```

**Command explanation:**
* `wait_for_status=green`: Wait until cluster is green
* `timeout=30s`: Maximum wait time (30 seconds)
* **Purpose:** Wait for cluster to reach desired status before proceeding
* **Use case:** Useful in scripts that need cluster to be healthy

**Wait for yellow status (acceptable for single node):**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cluster/health?wait_for_status=yellow&timeout=30s&pretty"
```

---

### 1.4 Detailed Cluster Health

Get detailed health information:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cluster/health?level=indices&pretty"
```

**Command explanation:**
* `level=indices`: Include index-level health information
* **Purpose:** See health status for each index
* **Alternative values:** `cluster` (default), `indices`, `shards`

**Get shard-level health:**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cluster/health?level=shards&pretty"
```


---

## 2. Monitoring Nodes

### 2.1 List All Nodes

**List nodes with basic information:**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/nodes?v"
```

**Command explanation:**
* `_cat/nodes`: Compact and aligned text (CAT) API for nodes
* `?v`: Verbose mode (show column headers)
* **Purpose:** View all nodes in the cluster with key metrics

**Output columns:**
* `ip`: Node IP address
* `heap.percent`: JVM heap memory usage percentage
* `ram.percent`: Total RAM usage percentage
* `cpu`: CPU usage percentage
* `load_1m`: 1-minute load average
* `node.role`: Node roles (mdi = master, data, ingest)

---

### 2.2 Node Statistics

**Get detailed node statistics:**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_nodes/stats?pretty"
```

**Get stats for specific node:**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_nodes/elasticsearch/stats?pretty"
```

**Command explanation:**
* `elasticsearch`: Node name (replace with your node name)
* **Purpose:** Get statistics for a specific node

---

### 2.3 Node Hot Threads

**Check which threads are consuming CPU:**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_nodes/hot_threads?pretty"
```

**Command explanation:**
* `_nodes/hot_threads`: Hot threads API
* **Purpose:** Identify threads that are consuming CPU (useful for performance troubleshooting)

---

## 3. Monitoring Indices

### 3.1 List All Indices

**Basic index listing:**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/indices?v"
```

---

### 3.2 List Indices with Filters

**List only open indices:**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/indices?v&h=index,status,docs.count,store.size"
```

**List indices sorted by size:**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/indices?v&s=store.size:desc"
```

**List indices matching pattern:**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/indices/logs-*?v"
```

---

### 3.3 Index Statistics

**Get statistics for all indices:**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_stats?pretty"
```

**Get stats for specific index:**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/logs-*/_stats?pretty"
```

---

### 3.4 Index Settings

**View index settings:**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/logs-*/_settings?pretty"
```

**View specific setting:**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/logs-*/_settings/index.number_of_replicas?pretty"
```

---

## 4. Monitoring Shards

### 4.1 List All Shards

**List all shards:**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/shards?v"
```

**Command explanation:**
* `_cat/shards`: CAT API for shards
* **Purpose:** View all shards and their status

**Important columns:**
* `index`: Index name
* `shard`: Shard number
* `prirep`: Primary (p) or replica (r)
* `state`: Shard state (STARTED, UNASSIGNED, etc.)
* `node`: Node where shard is located

---

### 4.2 Shard Allocation

**Check shard allocation:**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/allocation?v"
```

**Command explanation:**
* `_cat/allocation`: Shard allocation API
* **Purpose:** See how shards are distributed across nodes

**Check unassigned shards:**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/shards?v&h=index,shard,prirep,state,unassigned.reason"
```

**Command explanation:**
* Filter to show unassigned shards
* **Purpose:** Identify why shards cannot be assigned

---

## 5. Disk Space Monitoring

### 5.1 Disk Usage by Index

**List indices sorted by size:**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/indices?v&s=store.size:desc&h=index,docs.count,store.size,pri.store.size"
```

**Command explanation:**
* `&s=store.size:desc`: Sort by size descending
* `&h=index,docs.count,store.size,pri.store.size`: Show specific columns
* **Purpose:** Identify which indices are using the most disk space

---

### 5.2 Disk Usage by Node

**Check disk usage per node:**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/allocation?v"
```

**Command explanation:**
* Shows disk usage per node
* **Purpose:** Monitor disk usage across cluster nodes

**Output columns:**
* `shards`: Number of shards on node
* `disk.indices`: Disk used by indices
* `disk.used`: Total disk used
* `disk.avail`: Available disk space
* `disk.total`: Total disk space

---

### 5.3 Calculate Total Disk Usage

**Get cluster disk statistics:**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/allocation?v&h=disk.used,disk.avail,disk.total"
```

**Command explanation:**
* Shows disk usage summary
* **Purpose:** Calculate total cluster disk usage

---

## 6. Checking Logstash Pipeline Status

### 6.1 Check Logstash Service

**Check Logstash container status:**

```bash
docker compose ps logstash
```

**Command explanation:**
* `ps`: List running containers
* `logstash`: Service name
* **Purpose:** Verify Logstash container is running

**View Logstash logs:**

```bash
docker compose logs logstash
```

**Command explanation:**
* `logs`: View container logs
* **Purpose:** See Logstash startup and runtime logs

**Follow Logstash logs (real-time):**

```bash
docker compose logs -f logstash
```

**Command explanation:**
* `-f`: Follow log output (like `tail -f`)
* **Purpose:** Monitor Logstash logs in real-time

---

### 6.2 Check Logstash API

**Check if Logstash API is accessible:**

```bash
curl -X GET "http://localhost:9600"
```

**Command explanation:**
* `9600`: Default Logstash API port
* **Purpose:** Verify Logstash API is running

**Get Logstash node info:**

```bash
curl -X GET "http://localhost:9600/_node?pretty"
```

**Command explanation:**
* `_node`: Node information endpoint
* **Purpose:** Get Logstash node details

---

### 6.3 Pipeline Status

**Get pipeline status:**

```bash
curl -X GET "http://localhost:9600/_node/pipelines?pretty"
```

**Command explanation:**
* `_node/pipelines`: Pipeline status endpoint
* **Purpose:** Check if pipelines are running and processing events

**Get pipeline stats:**

```bash
curl -X GET "http://localhost:9600/_node/stats/pipelines?pretty"
```

**Command explanation:**
* `_node/stats/pipelines`: Pipeline statistics endpoint
* **Purpose:** Get detailed pipeline statistics (events processed, errors, etc.)

**From within container:**

```bash
docker compose exec logstash bash
curl -X GET "http://localhost:9600/_node/pipelines?pretty"
exit
```

---

## 7. Tracking Beats Agents Status

### 7.1 Check Filebeat Service

**Check Filebeat service status:**

```bash
sudo systemctl status filebeat
```

**Command explanation:**
* `systemctl status`: Check systemd service status
* `filebeat`: Service name
* **Purpose:** Verify Filebeat is running

**Expected output:**
* `active (running)`: Filebeat is healthy and sending data
* `inactive / failed`: Filebeat is not running, data may not be sending

**Start Filebeat (if stopped):**

```bash
sudo systemctl start filebeat
```

**Command explanation:**
* `start`: Start the service
* **Purpose:** Start Filebeat if it's not running

**Enable Filebeat to start on boot:**

```bash
sudo systemctl enable filebeat
```

**Command explanation:**
* `enable`: Enable service to start automatically on boot
* **Purpose:** Ensure Filebeat starts after system reboot

---

### 7.2 Check Metricbeat Service

**Check Metricbeat service status:**

```bash
sudo systemctl status metricbeat
```

**Command explanation:**
* Similar to Filebeat status check
* **Purpose:** Verify Metricbeat is running

**View Metricbeat logs:**

```bash
sudo journalctl -u metricbeat -f
```

**Command explanation:**
* `journalctl`: Systemd journal viewer
* `-u metricbeat`: Filter by service name
* `-f`: Follow log output
* **Purpose:** Monitor Metricbeat logs in real-time

---

### 7.3 Check Filebeat Registry

**View Filebeat registry (file positions):**

```bash
sudo cat /var/lib/filebeat/registry/filebeat/data.json | jq .
```

**Command explanation:**
* `/var/lib/filebeat/registry/`: Filebeat registry directory
* `jq .`: Format JSON output (requires `jq` package)
* **Purpose:** Check which files Filebeat is tracking and their positions

---

## 8. Index Management

### 8.1 Create Index Alias

**Create alias for index:**

```bash
curl -u elastic:changeme -X POST "http://localhost:9200/_aliases" \
  -H "Content-Type: application/json" \
  -d '{
    "actions": [
      {
        "add": {
          "index": "logs-2025.01.15",
          "alias": "logs-current"
        }
      }
    ]
  }'
```

**Command explanation:**
* `_aliases`: Index aliases API
* `"add"`: Add alias action
* `"index"`: Source index name
* `"alias"`: Alias name
* **Purpose:** Create an alias that points to an index (useful for switching indices)

---

### 8.2 List All Aliases

**List all aliases:**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/aliases?v"
```

**Command explanation:**
* `_cat/aliases`: List all aliases
* **Purpose:** View all index aliases

**Get aliases for specific index:**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/logs-*/_alias?pretty"
```

**Command explanation:**
* `_alias`: Get aliases for indices
* **Purpose:** See which aliases point to specific indices

---

## 9. Maintenance Tasks

### 9.1 Force Merge Index

**Force merge index to optimize:**

```bash
curl -u elastic:changeme -X POST "http://localhost:9200/logs-*/_forcemerge?max_num_segments=1"
```

**Command explanation:**
* `_forcemerge`: Force merge API
* `max_num_segments=1`: Merge to single segment
* **Purpose:** Optimize index by merging segments (reduces disk usage, improves search performance)
* **Note:** Use on read-only or old indices (can be resource-intensive)

---

### 9.2 Clear Cache

**Clear cache for all indices:**

```bash
curl -u elastic:changeme -X POST "http://localhost:9200/_cache/clear"
```

**Command explanation:**
* `_cache/clear`: Clear cache API
* **Purpose:** Clear all caches (field data, query cache, request cache)

**Clear cache for specific index:**

```bash
curl -u elastic:changeme -X POST "http://localhost:9200/logs-*/_cache/clear"
```

**Command explanation:**
* Clear cache for specific indices
* **Purpose:** Free up memory by clearing cache

---

### 9.3 Refresh Index

**Refresh all indices:**

```bash
curl -u elastic:changeme -X POST "http://localhost:9200/_refresh"
```

**Command explanation:**
* `_refresh`: Refresh API
* **Purpose:** Make recently indexed documents searchable immediately

**Refresh specific index:**

```bash
curl -u elastic:changeme -X POST "http://localhost:9200/logs-*/_refresh"
```

---

### 9.4 Close Index

**Close index (make it read-only):**

```bash
curl -u elastic:changeme -X POST "http://localhost:9200/old-logs-2025.01.01/_close"
```

**Command explanation:**
* `_close`: Close index API
* **Purpose:** Close index to free up resources (index remains but cannot be written to or searched)

**Open closed index:**

```bash
curl -u elastic:changeme -X POST "http://localhost:9200/old-logs-2025.01.01/_open"
```

**Command explanation:**
* `_open`: Open index API
* **Purpose:** Reopen a closed index

---

### 9.5 Delete Index

**Delete specific index:**

```bash
curl -u elastic:changeme -X DELETE "http://localhost:9200/old-logs-2025.01.01"
```

**Command explanation:**
* `-X DELETE`: HTTP DELETE method
* **Purpose:** Permanently delete an index and all its data
* **Warning:** This action cannot be undone

**Delete indices matching pattern:**

```bash
curl -u elastic:changeme -X DELETE "http://localhost:9200/old-logs-*"
```

**Command explanation:**
* `old-logs-*`: Index pattern
* **Purpose:** Delete multiple indices matching pattern
* **Warning:** Be very careful with wildcard deletions

---

## 10. Index Lifecycle Management (ILM) Basics

### 10.1 Create ILM Policy

**Create simple ILM policy:**

```bash
curl -u elastic:changeme -X PUT "http://localhost:9200/_ilm/policy/logs-policy" \
  -H "Content-Type: application/json" \
  -d '{
    "policy": {
      "phases": {
        "hot": {
          "actions": {
            "rollover": {
              "max_size": "10GB",
              "max_age": "7d"
            }
          }
        },
        "delete": {
          "min_age": "30d",
          "actions": {
            "delete": {}
          }
        }
      }
    }
  }'
```

---

### 10.2 Apply ILM Policy to Index Template

**Create index template with ILM:**

```bash
curl -u elastic:changeme -X PUT "http://localhost:9200/_index_template/logs-template" \
  -H "Content-Type: application/json" \
  -d '{
    "index_patterns": ["logs-*"],
    "template": {
      "settings": {
        "index.lifecycle.name": "logs-policy",
        "index.lifecycle.rollover_alias": "logs"
      }
    }
  }'
```

**Command explanation:**
* `index_patterns`: Index pattern to match
* `index.lifecycle.name`: ILM policy name
* `index.lifecycle.rollover_alias`: Alias for rollover
* **Purpose:** Apply ILM policy to new indices matching pattern

---

### 10.3 Check ILM Status

**Get ILM status for indices:**

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_ilm/explain?pretty"
```

**Command explanation:**
* `_ilm/explain`: ILM explain API
* **Purpose:** See ILM status and current phase for all indices

---

## 11. Log Retention Best Practices

### 11.1 Why Log Retention Is Important

* **Prevents disk from getting full:** Old logs consume disk space
* **Improves search performance:** Fewer indices mean faster searches
* **Keeps the cluster stable:** Reduces resource usage
* **Cost management:** Less storage means lower costs

---

### 11.2 Simple Retention Practices

**Manual deletion (for small setups):**

```bash
# Delete old index
curl -u elastic:changeme -X DELETE "http://localhost:9200/old-logs-2025.01.01"
```

**Using ILM (recommended for production):**

* Set up ILM policy to automatically delete old indices
* Configure retention period based on requirements
* Monitor disk usage regularly

**Retention periods:**
* **Development:** 7 days
* **Testing:** 14-30 days
* **Production:** 30-90 days (depending on compliance requirements)

---

## 12. Troubleshooting Common Issues

### 12.1 Cluster Health is Red

**Problem:** Cluster health shows red status

**Diagnosis:**

```bash
# Check cluster health
curl -u elastic:changeme -X GET "http://localhost:9200/_cluster/health?pretty"

# Check unassigned shards
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/shards?v&h=index,shard,prirep,state,unassigned.reason"
```

**Common causes:**
* Primary shard is missing
* Disk space full
* Node failure

**Solutions:**
* Check disk space: `df -h`
* Check node status: `docker compose ps elasticsearch`
* Restart Elasticsearch if needed: `docker compose restart elasticsearch`

---

### 12.2 High Disk Usage

**Problem:** Disk space is running low

**Diagnosis:**

```bash
# Check disk usage by index
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/indices?v&s=store.size:desc"

# Check disk usage by node
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/allocation?v"
```

**Solutions:**
* Delete old indices
* Force merge old indices
* Close old indices
* Increase disk space

---

### 12.3 Logstash Not Processing Events

**Problem:** Logstash is running but not processing events

**Diagnosis:**

```bash
# Check Logstash status
docker compose ps logstash

# Check Logstash logs
docker compose logs -f logstash

# Check pipeline status
curl -X GET "http://localhost:9600/_node/pipelines?pretty"
```

**Common causes:**
* Pipeline configuration error
* Input source not available
* Elasticsearch connection issue

**Solutions:**
* Check pipeline configuration: `docker compose exec logstash cat /usr/share/logstash/pipeline/*.conf`
* Verify Elasticsearch connection
* Check input sources (file paths, ports, etc.)

---

### 12.4 Beats Not Sending Data

**Problem:** Filebeat/Metricbeat is running but not sending data

**Diagnosis:**

```bash
# Check service status
sudo systemctl status filebeat

# Check logs
sudo journalctl -u filebeat -n 50

# Check registry
sudo cat /var/lib/filebeat/registry/filebeat/data.json
```

**Common causes:**
* Configuration error
* Input file not accessible
* Elasticsearch connection issue
* Permission problems

**Solutions:**
* Verify configuration: `sudo filebeat test config`
* Check file permissions
* Verify Elasticsearch connection
* Restart service: `sudo systemctl restart filebeat`

---

## 13. Daily Monitoring Checklist

Use this checklist for daily monitoring:

1. **Cluster Health**
   ```bash
   curl -u elastic:changeme -X GET "http://localhost:9200/_cluster/health?pretty"
   ```
   * Check status (should be green or yellow)
   * Check for unassigned shards

2. **Disk Usage**
   ```bash
   curl -u elastic:changeme -X GET "http://localhost:9200/_cat/allocation?v"
   ```
   * Monitor disk usage per node
   * Identify indices using most space

3. **Index Count**
   ```bash
   curl -u elastic:changeme -X GET "http://localhost:9200/_cat/indices?v"
   ```
   * Verify expected indices exist
   * Check for unexpected indices

4. **Logstash Status** (if used)
   ```bash
   docker compose ps logstash
   curl -X GET "http://localhost:9600/_node/pipelines?pretty"
   ```
   * Verify Logstash is running
   * Check pipeline status

5. **Beats Status** (if used)
   ```bash
   sudo systemctl status filebeat
   sudo systemctl status metricbeat
   ```
   * Verify Beats are running
   * Check for errors in logs

6. **Remove Old Indices**
   ```bash
   curl -u elastic:changeme -X DELETE "http://localhost:9200/old-index-name"
   ```
   * Delete indices beyond retention period

---

## 14. Quick Reference Commands

**Cluster Health:**
```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cluster/health?pretty"
```

**List Indices:**
```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/indices?v"
```

**List Nodes:**
```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/nodes?v"
```

**List Shards:**
```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/shards?v"
```

**Disk Usage:**
```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/allocation?v"
```

**Logstash Status:**
```bash
docker compose ps logstash
docker compose logs -f logstash
```

**Filebeat Status:**
```bash
sudo systemctl status filebeat
sudo journalctl -u filebeat -f
```

**Metricbeat Status:**
```bash
sudo systemctl status metricbeat
sudo journalctl -u metricbeat -f
```

---
