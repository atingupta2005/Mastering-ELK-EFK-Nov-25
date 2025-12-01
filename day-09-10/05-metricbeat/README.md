# Metric Collection Hands‑On Guide (Focused on Metricbeat + Elasticsearch + Logstash)

> **Note for docker-elk users:**
> - Metricbeat runs on host (use `systemctl` for it)
> - Default credentials: `elastic:changeme` and `logstash_internal:changeme` (update if changed in `.env`)
> - Logstash configs go in: `logstash/pipeline/` directory (from docker-elk directory)
> - Use `docker compose` commands for Logstash/Elasticsearch/Kibana

## Installing Metricbeat on CentOS Stream 9

### Step 1: Import Elastic GPG Key

```
sudo rpm --import https://artifacts.elastic.co/GPG-KEY-elasticsearch
```

### Step 2: Add Elastic Repository
 - Warning: Optional and only add if needed

```
sudo tee /etc/yum.repos.d/elastic.repo > /dev/null << 'EOF'
[elastic-9.x]
name=Elastic repository for 9.x packages
baseurl=https://artifacts.elastic.co/packages/9.x/yum
enabled=1
gpgcheck=1
gpgkey=https://artifacts.elastic.co/GPG-KEY-elasticsearch
EOF
```

### Step 3: Install Metricbeat

```
sudo dnf install metricbeat -y
```

### Step 4: Enable & Start Metricbeat

```
sudo systemctl enable metricbeat
sudo systemctl start metricbeat
```


# 1. What Is Metric Collection?

Metric collection refers to gathering **system-level**, **service-level**, or **application-level** telemetry such as:

* CPU usage
* Memory usage
* Disk I/O & filesystem stats
* Network throughput
* Process statistics
* Service and daemon metrics
* Application-specific metrics (MySQL, Nginx, Apache, Docker, Kubernetes, etc.)

Metricbeat is the Elastic component designed specifically for collecting these metrics.

---

# 2. Understanding Metricbeat Architecture

Metricbeat uses a simple architecture:

```
Modules → Metricsets → Publisher → Logstash/Elasticsearch
```

### Components

| Component     | Purpose                                                       |
| ------------- | ------------------------------------------------------------- |
| **Module**    | High-level group (system, apache, mysql, docker, nginx, etc.) |
| **Metricset** | Each module has multiple metricsets (e.g., CPU, memory, load) |
| **Input**     | Metricbeat pulls data from system APIs or services            |
| **Output**    | Sends to Elasticsearch or Logstash                            |

Metricbeat collects metrics at regular intervals (default: 10s).

---

# 3. Enable System Metrics (CPU, Memory, Disk, Network)

Metricbeat includes a built-in `system` module. To enable it:

```
sudo metricbeat modules enable system
```

Verify:

```
sudo metricbeat modules list
```

You should see:

```
system (enabled)
```

---

# 4. Configure Metricbeat for Elasticsearch Output

Edit the configuration:

```
sudo nano /etc/metricbeat/metricbeat.yml
```

Ensure this section is correct:

```
output.elasticsearch:
  hosts: ["http://localhost:9200"]
  username: "elastic"
  password: "changeme"
```

Disable Logstash output:

```
output.logstash:
  enabled: false
```

Restart Metricbeat:

```
sudo systemctl restart metricbeat
```

Check logs:

```
sudo journalctl -u metricbeat -f
```

---

# 5. Configure Metricbeat to Send Metrics via Logstash (Optional)

If you want Logstash to process metrics, modify:

```
output.logstash:
  enabled: true
  hosts: ["localhost:5044"]
```

Disable ES output:

```
output.elasticsearch:
  enabled: false
```

### Create Logstash pipeline (from docker-elk directory)

```
nano logstash/pipeline/metricbeat.conf
```

```
input {
  beats {
    port => 5044
  }
}

filter {
  mutate {
    add_tag => ["from_metricbeat"]
  }
}

output {
  elasticsearch {
    hosts => ["http://elasticsearch:9200"]
    index => "metricbeat-system-%{+YYYY.MM.dd}"
    user => "logstash_internal"
    password => "changeme"
  }
}
```

Restart Logstash (from docker-elk directory):

```
docker compose restart logstash
```

---

# 6. Validate Metric Collection in Elasticsearch

Check indices:

```
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/indices?v" | grep metricbeat
```

Example:

```
.green .ds-metricbeat-9-2025.11.21-000001
```

Retrieve metrics:

```
curl -u elastic:changeme -X GET "http://localhost:9200/metricbeat-*/_search?pretty&size=1"
```

---

# 7. Create Data View in Kibana

1. Open **Kibana → Discover**
2. Click **Create Data View**
3. Name: `metricbeat-system`
4. Index pattern: `metricbeat-*`
5. Time field: `@timestamp`
6. Save

You will now see:

* system.cpu.total.pct
* system.memory.actual.free
* system.network.in.bytes
* system.filesystem.used.pct

---

# 8. Enable More Metricbeat Modules

Metricbeat has 40+ modules. Some examples:

```
sudo metricbeat modules enable apache
sudo metricbeat modules enable nginx
sudo metricbeat modules enable docker
sudo metricbeat modules enable mysql
sudo metricbeat modules enable system
```

List all modules:

```
metricbeat modules list
```

---

# 9. Example: Apache Metrics Module

Enable:

```
sudo metricbeat modules enable apache
```

Edit module config:

```
sudo nano /etc/metricbeat/modules.d/apache.yml
```

```
- module: apache
  metricsets:
    - status
  period: 10s
  hosts: ["http://10.0.18.1/server-status?auto"]
```

You must enable `mod_status` in Apache.

Restart Metricbeat:

```
sudo systemctl restart metricbeat
```

---

# 10. Example: Docker Metrics

Enable module:

```
sudo metricbeat modules enable docker
```

Docker metrics show:

* CPU per container
* Mem per container
* I/O
* Network usage

---

# 11. Example: Nginx Metrics

```
sudo metricbeat modules enable nginx
```

Configure host:

```
- module: nginx
  metricsets: ["stubstatus"]
  hosts: ["http://localhost/nginx_status"]
```

---

# 12. Example: MySQL Metrics

Enable:

```
sudo metricbeat modules enable mysql
```

Edit:

```
- module: mysql
  hosts: ["root:password@tcp(127.0.0.1:3306)/"]
  metricsets:
    - status
    - galera_status
```

---

# 13. Monitoring Metricbeat Itself

Check status:

```
sudo systemctl status metricbeat
```

Check logs:

```
sudo journalctl -u metricbeat -f
```

Test configuration:

```
sudo metricbeat test config
```

Test output:

```
sudo metricbeat test output
```

---

# 14. Troubleshooting Guide

### 1. No metrics in Elasticsearch

Check output:

```
sudo metricbeat test output
```

Check ES connectivity:

```
curl -u elastic:changeme http://localhost:9200
```

### 2. Metricbeat not reading modules

```
metricbeat modules list
```

Ensure module config is enabled.

### 3. Permission issues

Set permissions:

```
sudo chmod -R 755 /etc/metricbeat
```

### 4. SELinux blocking

Check:

```
sestatus
```

If enforcing:

```
sudo semanage port -a -t http_port_t -p tcp 5066
```
