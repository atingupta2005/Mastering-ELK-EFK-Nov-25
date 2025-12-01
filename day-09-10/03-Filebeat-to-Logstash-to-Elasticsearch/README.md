# **Filebeat → Logstash → Elasticsearch**

> **Note for docker-elk users:**
> - All commands should be run from the `docker-elk` directory
> - Default credentials: `elastic:changeme` and `logstash_internal:changeme` (update if changed in `.env`)
> - Logstash configs go in: `logstash/pipeline/` directory
> - Filebeat runs on host (use `systemctl` for it)
> - Use `docker compose` commands for Logstash/Elasticsearch/Kibana

# **1. Architecture Overview**

Below is the complete flow:

```
   Application Logs (/var/log/myapp/*)
                 │
            [Filebeat]
   - Reads & harvests files
   - Adds metadata
   - Ships logs
                 │ beats protocol (port 5044)
                 ▼
            [Logstash]
   - Input: beats
   - Filter: grok / mutate / date
   - Output: Elasticsearch
                 │ HTTP JSON
                 ▼
        [Elasticsearch Index]
                 ▼
           [Kibana Discover]
```

### **Required Ports**

| Component     | Port | Purpose     |
| ------------- | ---- | ----------- |
| Logstash      | 5044 | Beats input |
| Elasticsearch | 9200 | HTTP API    |
| Kibana        | 5601 | UI          |

---

# **2. Filebeat → Logstash Pipeline Configuration**

We configure Filebeat to send logs to Logstash.

## **2.1 Filebeat Configuration**

Edit:

```
sudo nano /etc/filebeat/filebeat.yml
```

### **Minimal clean configuration:**

```
filebeat.inputs:
  - type: filestream
    id: myapp-logs
    enabled: true
    paths:
      - /var/log/myapp/*.log
      - /var/log/myapp/*.json

output.logstash:
  hosts: ["localhost:5044"]
```

Save → exit → test:

```
sudo filebeat test config
sudo filebeat test output
```

Restart:

```
sudo systemctl restart filebeat
sudo systemctl status filebeat
```

---

# **3. Logstash Configuration**

Logstash receives Filebeat logs → parses → sends to Elasticsearch.

Edit Logstash pipeline (from docker-elk directory):

```
nano logstash/pipeline/01-beats.conf
```

### **Pipeline Definition**

```
input {
  beats {
    port => 5044
  }
}

filter {
  # Example filter: Add tag for tracking
  mutate {
    add_tag => ["from_filebeat"]
  }

  # Example Apache-style grok parsing
  # Uncomment if needed
  # grok {
  #   match => { "message" => "%{COMBINEDAPACHELOG}" }
  # }
}

output {
  elasticsearch {
    hosts => ["http://elasticsearch:9200"]
    user => "logstash_internal"
    password => "changeme"
    index => "logstash-beats-%{+YYYY.MM.dd}"
  }
  stdout { codec => rubydebug }
}
```

Restart Logstash (from docker-elk directory):

```
docker compose restart logstash
docker compose ps logstash
```

Watch live logs:

```
docker compose logs -f logstash
```

---

# **4. Generating Logs for Testing**

We generate both `.log` and `.json` logs continuously.

```
sudo mkdir -p /var/log/myapp
sudo touch /var/log/myapp/app.log /var/log/myapp/app.json
sudo chmod 666 /var/log/myapp/*
```

Run generator:

```
while true; do
  LEVEL=$(shuf -e INFO WARN ERROR DEBUG TRACE -n 1)
  USER=$(shuf -e admin user1 user2 guest api-service backend-service -n 1)
  ACTION=$(shuf -e login logout update delete create read write access modify execute -n 1)
  IP="192.168.$((RANDOM%255)).$((RANDOM%255))"
  ID=$((RANDOM % 100000))
  TS="$(date '+%Y-%m-%d %H:%M:%S')"
  TS_JSON="$(date '+%Y-%m-%dT%H:%M:%S')"

  echo "$TS $LEVEL user=$USER action=$ACTION ip=$IP record_id=$ID" |
    sudo tee -a /var/log/myapp/app.log > /dev/null

  echo "{\"timestamp\":\"$TS_JSON\",\"level\":\"$LEVEL\",\"user\":\"$USER\",\"action\":\"$ACTION\",\"ip\":\"$IP\",\"record_id\":$ID}" |
    sudo tee -a /var/log/myapp/app.json > /dev/null

  for i in {1..10}; do
    LEVEL2=$(shuf -e INFO WARN ERROR DEBUG -n 1)
    echo "$TS $LEVEL2 burst_log=true id=$RANDOM message=\"Auto-generated log entry\"" |
      sudo tee -a /var/log/myapp/app.log > /dev/null
  done

  sleep 1

done
```

This will generate hundreds of logs every second.

---

# **5. Validating Logs Flow**

## **5.1 Check Filebeat → Logstash connection**

```
sudo journalctl -u filebeat -f | grep -i 'harvester\|logstash'
```

Look for:

* `Connected to logstash`
* `Harvester started`

## **5.2 Check Logstash receiving logs**

```
sudo journalctl -u logstash -f
```

Look for:

* `Beats inputs: started`
* `event received`
* rubydebug output in console

## **5.3 Check Elasticsearch output**

```
curl -u elastic:changeme "http://localhost:9200/_cat/indices?v" | grep logstash
```

You should see:

```
logstash-beats-2025.11.19
```

---

# **6. Creating Kibana Data Views**

### **6.1 For Logstash Indexes**

1. Open Kibana → *Stack Management*
2. *Data Views* → Create
3. Pattern:

   ```
   logstash-beats-*
   ```
4. Choose `@timestamp` as time field.

### **6.2 For Filebeat Data Streams**

If you use Filebeat → Elasticsearch directly:

```
filebeat-*
```

---

# **7. Practical Labs & Exercises**

## **7.1 Lab – Parse Apache Logs Using Grok**

Example Apache log:

```
192.168.1.10 - - [12/Nov/2025:21:15:32 +0000] "GET /index.html HTTP/1.1" 200 532
```

Create pipeline (from docker-elk directory):

```
nano logstash/pipeline/apache.conf
```

```
input {
  beats { port => 5044 }
}

filter {
  grok {
    match => { "message" => "%{COMBINEDAPACHELOG}" }
  }

  date {
    match => ["timestamp", "dd/MMM/YYYY:HH:mm:ss Z"]
    target => "@timestamp"
  }
}

output {
  elasticsearch {
    hosts => ["http://elasticsearch:9200"]
    user => "logstash_internal"
    password => "changeme"
    index => "apache-logs-%{+YYYY.MM.dd}"
  }

  stdout { codec => rubydebug }
}
```

Restart (from docker-elk directory):

```
docker compose restart logstash
```

---

## **7.2 Lab – Extract IP & Status Code**

```
filter {
  grok {
    match => { "message" => "%{IP:client_ip} - - \[%{HTTPDATE:timestamp}\] \"%{WORD:method} %{DATA:url} HTTP/%{NUMBER:http_version}\" %{NUMBER:status_code} %{NUMBER:bytes}" }
  }
}
```

---

## **7.3 Lab – Ingest System Logs with Filebeat**

Enable system module:

```
sudo filebeat modules enable system
sudo filebeat setup
sudo systemctl restart filebeat
```

Data appears under:

```
filebeat-*
```

---

## **7.4 Lab – Visualize in Kibana**

* Create Data View
* Use Discover to filter

  ```
  status_code: 500
  client_ip: 192.168.*
  method: GET
  ```
* Save search
* Create visualization (bar/pie/table)

---

# **8. Troubleshooting Guide (Quick Commands)**

### **Filebeat Errors**

```
sudo journalctl -u filebeat -f
sudo filebeat test config
sudo filebeat test output
```

### **Logstash Errors**

```
docker compose logs -f logstash
docker compose exec logstash /usr/share/logstash/bin/logstash --path.settings /usr/share/logstash/config -t
```

### **Elasticsearch Problems**

```
curl -u elastic:changeme http://localhost:9200/_cluster/health?pretty
```

### **Filebeat → Logstash Connectivity**

```
telnet localhost 5044
```

Should open the connection (blank screen).

### **Permissions Issues**

```
sudo chmod 666 /var/log/myapp/*
```

### **Registry Issues**

```
sudo systemctl stop filebeat
sudo rm -rf /var/lib/filebeat/registry
sudo systemctl start filebeat
```

---

# **9. Final Expected Outcome**

You should now see:

* Logs generated in `/var/log/myapp/`
* Filebeat harvesting logs
* Logstash receiving logs
* Elasticsearch creating indexes like:

  * `logstash-beats-YYYY.MM.DD`
* Kibana Discover showing structured parsed logs
