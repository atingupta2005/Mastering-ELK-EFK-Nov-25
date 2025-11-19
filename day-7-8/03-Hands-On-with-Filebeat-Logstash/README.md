# Hands-On Guide: Filebeat & Logstash (Elastic Stack 9.x, CentOS 8 Stream Compatible)

## Network Topology

Below is an example setup (replace IPs as needed):

| Component                   | Example IP                  | Description                  |
| --------------------------- | --------------------------- | ---------------------------- |
| Elasticsearch Server        | 10.0.18.1                | Receives and stores logs     |
| Logstash Server             | 10.0.18.4                | Processes logs from Filebeat |
| Kibana UI                   | 10.0.18.1                | Visualization console        |
| Filebeat Nodes (18 systems) | 10.0.18.7 – 10.0.18.52 | Servers generating logs      |

Replace these IPs with your actual network IPs.

---

# 13. Install Filebeat on Local System (CentOS 8 Stream)

Run the following commands **on each Filebeat node** (18 machines).

### Download and Install

```bash
wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-9.2.1-x86_64.rpm
sudo rpm -ivh filebeat-9.2.1-x86_64.rpm
```

### Enable and Start Filebeat

```bash
sudo systemctl enable filebeat
sudo systemctl start filebeat
```

### Verify Installation

```bash
filebeat version
sudo systemctl status filebeat
```

---

# 14. Configure Filebeat to Read Log Files

Main Filebeat config file:

```
/etc/filebeat/filebeat.yml
```

### Create a Sample Log File

```bash
sudo mkdir -p /var/log/myapp
sudo bash -c 'echo "2025-01-01 INFO App started" >> /var/log/myapp/app.log'
```

### Configure Filebeat Log Input

Edit the config:

```bash
sudo nano /etc/filebeat/filebeat.yml
```

Replace input section with:

```yaml
filebeat.inputs:
  - type: log
    id: myapp-logs
    enabled: true
    paths:
      - /var/log/myapp/*.log
      - /var/log/myapp/*.json
```

Save & restart Filebeat:

```bash
sudo systemctl restart filebeat
```

### Generate Logs for Testing

```bash
sudo bash -c 'echo "2025-01-01 ERROR Something failed" >> /var/log/myapp/app.log'
sudo bash -c 'echo "2025-01-01 DEBUG Debug message" >> /var/log/myapp/app.log'
```

---

# 15. Send Data Directly to Elasticsearch

This setup is for when Filebeat sends logs **without Logstash**.

### Edit Filebeat Output

```bash
sudo nano /etc/filebeat/filebeat.yml
```

Update the output section:

```yaml
output.elasticsearch:
  hosts: ["http://10.0.18.1:9200"]
  username: "<Your-User-Name>"
  password: "<Your-Password>"
```

Disable Logstash output:

```yaml
output.logstash:
  enabled: false
```

Restart Filebeat:

```bash
sudo systemctl restart filebeat
```

### Verify Elasticsearch Received Logs

```bash
curl -u your-user-name:-your-password -X GET "http://10.0.18.1:9200/_cat/indices?v" | grep filebeat
```

---

# 16. Send Data via Logstash (Recommended for Parsing)

This is the preferred production setup.

## Step 1: Configure Filebeat to Send Data to Logstash

```bash
sudo nano /etc/filebeat/filebeat.yml
```

Update output:

```yaml
output.logstash:
  hosts: ["10.0.18.22:5044"]
```

Disable Elasticsearch output:

```yaml
output.elasticsearch:
  enabled: false
```

Restart Filebeat:

```bash
sudo systemctl restart filebeat
```

---

# Step 2: Install Logstash 9.2.1 on Logstash Server (10.0.18.22)

Run these commands **on the Logstash server only**.

### Download and Install Logstash

```bash
wget https://artifacts.elastic.co/downloads/logstash/logstash-9.2.1-x86_64.rpm
sudo rpm -ivh logstash-9.2.1-x86_64.rpm
```

### Enable and Start Logstash

```bash
sudo systemctl enable logstash
sudo systemctl start logstash
```

### Verify Installation

```bash
logstash --version
sudo systemctl status logstash
```

---

# Step 3: Configure Logstash Input → Filter → Output

Create Logstash config:

```bash
sudo nano /etc/logstash/conf.d/01-beats.conf
```

Paste:

```ruby
input {
  beats {
    port => 5044
  }
}

filter {
  mutate {
    add_tag => ["from_filebeat"]
  }
}

output {
  elasticsearch {
    hosts => ["http://10.0.18.1:9200"]
    index => "logstash-beats-%{+YYYY.MM.dd}"
  }
  stdout { codec => rubydebug }
}
```

Restart Logstash:

```bash
sudo systemctl restart logstash
```

### Validate Logstash Listening on Port 5044

```bash
sudo ss -tulnp | grep 5044
```

---

# 17. Explore Logs in Kibana Discover

Open Kibana from browser:

```
http://10.0.18.1:5601
```

## Create Index Patterns

### For direct Elasticsearch ingestion

```
filebeat-*
```

### For Logstash ingestion

```
logstash-beats-*
```

## View Logs

Go to:
**Kibana → Discover**

You should now see logs from all Filebeat nodes.

