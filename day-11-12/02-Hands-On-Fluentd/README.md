# Fluentd Installation & Configuration

## 1. Install Fluentd & Plugins

```bash
curl -fsSL https://toolbelt.treasuredata.com/sh/install-redhat-fluent-package5-lts.sh | sh

sudo fluent-gem install fluent-plugin-elasticsearch
sudo fluent-gem install fluent-plugin-grok-parser
```

---

## 2. Data Provisioning

```bash
sudo mkdir -p /opt/student_logs/S105/
cd /opt/student_logs/S105/
sudo curl -L -o access.log https://raw.githubusercontent.com/elastic/examples/master/Common%20Data%20Formats/apache_logs/apache_logs
sudo chmod 644 /opt/student_logs/S105/access.log
```

---

## 3. Configuration File Setup

```bash
sudo cp /etc/fluent/fluentd.conf /etc/fluent/fluentd.conf.bak
sudo vi /etc/fluent/fluentd.conf
```

**Paste the following exactly:**

```xml
# ===================================================================
# SECTION 1: INPUT & PARSING
# ===================================================================

<source>
  @type tail
  path /opt/student_logs/S105/access.log
  # Position file tracks read progress in the new directory structure
  pos_file /var/log/fluent/s105-access.log.pos
  tag s105.apache.access
  
  # CRITICAL FIX: Forces reading from the beginning of the static file
  read_from_head true
  
  <parse>
    @type grok
    # Standard Apache Combined Log Pattern
    grok_pattern %{IPORHOST:client_ip} %{USER:ident} %{USER:auth} \[%{HTTPDATE:timestamp}\] "(?:%{WORD:request_method} %{NOTSPACE:request_url}(?: HTTP/%{NUMBER:http_version})?|%{DATA:raw_request})" %{NUMBER:status_code} (?:%{NUMBER:bytes}|-)
    
    # Timestamp Mapping (Maps 2015 log time to event time)
    time_key timestamp
    time_format %d/%b/%Y:%H:%M:%S %z
    keep_time_key true
    
    # Type Conversion for Kibana Aggregations
    types status_code:integer,bytes:integer
  </parse>
</source>

# ===================================================================
# SECTION 2: OUTPUT TO ELASTICSEARCH
# ===================================================================

<match s105.**>
  @type elasticsearch
  
  # Core Connection
  host localhost
  port 9200
  scheme http
  
  # Authentication
  user elastic
  password changeme
  
  # Index Destination
  index_name s105-weblogs
  
  # Elastic 9.x Compatibility Flags
  suppress_type_name true
  include_timestamp true
  
  # Buffer Strategy
  <buffer>
    @type file
    path /var/log/fluent/buffer/s105
    flush_interval 5s
  </buffer>
</match>
```

---

## 4. Execution Strategy (Strict Restart)

```bash
sudo systemctl stop fluentd
sudo rm -f /var/log/fluent/s105-access.log.pos
sudo mkdir -p /var/log/fluent/buffer/s105
sudo chmod -R 777 /var/log/fluent/
sudo systemctl enable --now fluentd
```

---

## 5. Validation Check

```bash
curl -u elastic:changeme -X GET "http://localhost:9200/_cat/indices/s105-weblogs?v"
```

