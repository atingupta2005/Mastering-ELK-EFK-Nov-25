# Day 12 – Monitoring & Maintenance (Elasticsearch 9.x | CentOS | HTTP)

> **Note for docker-elk users:**
> - All commands should be run from the `docker-elk` directory
> - Default credentials: `elastic:changeme` (update if changed in `.env`)
> - Filebeat/Metricbeat run on host (use `systemctl` for them)
> - Use `docker compose` commands for Logstash/Elasticsearch/Kibana

---

## 1. Checking Elasticsearch Health (_cluster/health)

Cluster health shows the **overall working state of Elasticsearch**.

### Step 1 – Check Cluster Health

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cluster/health?pretty"
```

### Understanding the Status

* **green** → All primary and replica shards are working
* **yellow** → All primary shards are working, some replicas missing
* **red** → Some primary shards are not working (data risk)

### Simple Classroom Use

* Green → System is healthy
* Yellow → Acceptable for single‑node lab
* Red → Needs immediate attention

---

## 2. Monitoring Indices (_cat/indices)

This command shows **all indices and their storage usage**.

### Step 1 – List All Indices

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/indices?v"
```

### Important Columns to Observe

* `health` → Index health
* `index` → Index name
* `docs.count` → Number of documents
* `store.size` → Disk space used

### Simple Classroom Use

* Identify large indices
* Check if today’s log index is created

---

## 3. Checking Logstash Pipeline Status

This section is applicable **only if Logstash is being used in the lab**.

### Step 1 – Check Logstash Service (from docker-elk directory)

```bash
docker compose ps logstash
```

Service should show **Up** status. To view logs:

```bash
docker compose logs logstash
```

---

### Step 2 – Check Logstash API (If Enabled)

```bash
curl -X GET "http://localhost:9600"
```

If Logstash API is running, you will see basic pipeline information. Alternatively, use:

```bash
docker compose logs -f logstash
```

---

## 4. Tracking Beats Agents Status

This section is applicable when **Filebeat or Metricbeat is used**.

### Step 1 – Check Filebeat Service

```bash
sudo systemctl status filebeat
```

### Step 2 – Check Metricbeat Service (If Installed)

```bash
sudo systemctl status metricbeat
```

If the service is:

* **active (running)** → Beats agent is healthy
* **inactive / failed** → Data may not be sending

---

## 5. Best Practices for Log Retention (Simple Guidelines)

Log retention means **how long old logs are kept in Elasticsearch**.

### Why Log Retention Is Important

* Prevents disk from getting full
* Improves search performance
* Keeps the cluster stable

---

### Simple Retention Practices (Training‑Friendly)

* Keep only **7–30 days of logs** in training environments
* Delete very old test indices manually
* Avoid keeping unused indices

### Simple Manual Deletion Example

```bash
curl -u elastic:changeme -X DELETE "http://localhost:9200/old-logs-2025.01.01"
```

---

## Quick Daily Maintenance Checklist

Use this simple checklist during daily monitoring:

1. Check cluster health
2. Check index disk usage
3. Check Logstash service (if used)
4. Check Beats services (if used)
5. Remove very old unused indices

---

## Verification Commands (Quick Reference)

Check cluster health:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cluster/health?pretty"
```

Check indices:

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/indices?v"
```

Check Logstash (from docker-elk directory):

```bash
docker compose ps logstash
```

Check Filebeat:

```bash
sudo systemctl status filebeat
```

Check Metricbeat:

```bash
sudo systemctl status metricbeat
```

---
