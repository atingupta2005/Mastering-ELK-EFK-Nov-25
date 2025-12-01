# **Logstash Parsing & Pipelines**

# **1. Logstash Architecture**

A Logstash pipeline has 3 sections:

```
input   →   filter   →   output
```

### **Input**

Where logs come from:

* Beats (Filebeat)
* File
* Stdin
* Syslog
* HTTP

### **Filter**

Where logs are transformed using:

* grok
* mutate
* dissect
* json
* date
* geoip
* kv
* fingerprint

### **Output**

Where logs are sent:

* Elasticsearch
* File
* Stdout
* Kafka

---

# **2. Understanding the Logstash Pipeline Structure**

A basic pipeline file (`/etc/logstash/conf.d/my.conf`) looks like:

```ruby
input {
  beats {
    port => 5044
  }
}

filter {
  grok { match => { "message" => "... pattern ..." } }
}

output {
  elasticsearch {
    hosts => ["http://10.0.18.1:9200"]
    username => "atin.gupta"
    password => "2313634"
  }
}
```

---

# **3. Inputs in Logstash**

## **3.1 Beats Input (Filebeat → Logstash)**

Most common in production.

```ruby
input {
  beats {
    port => 5044
  }
}
```

Used when Filebeat forwards logs.

---

## **3.2 File Input (for testing)**

```ruby
input {
  file {
    path => "/var/log/test.log"
    start_position => "beginning"
  }
}
```

# **4. Filters in Logstash (Deep Dive)**

Logstash filters are where the **processing** happens.

We will cover:

* grok
* dissect
* mutate
* date
* json
* kv
* geoip
* conditionals

---

# **5. Grok Filter (Core of Log Parsing)**

### **5.1 Basic Grok Example**

```ruby
filter {
  grok {
    match => {
      "message" => "%{IP:client_ip} %{WORD:method} %{URIPATH:url} %{NUMBER:status}"
    }
  }
}
```

---

### **5.2 Multiple Grok Patterns (Fallback)**

```ruby
grok {
  match => {
    "message" => [
      "%{COMBINEDAPACHELOG}",
      "%{IP:ip} %{WORD:method} %{URIPATH:url}",
      "%{DATA:msg}"
    ]
  }
}
```

The first matched pattern wins.

---

### **5.3 Named Captures with Types**

```ruby
%{NUMBER:response_time:int}
```

Converts numeric fields to integers.

---

# **6. Dissect Filter (Alternative to Grok)**

Dissect is faster and used when log structure is predictable.

Example:

```
2025-01-01 INFO user admin login ok
```

Dissect pattern:

```ruby
dissect {
  mapping => {
    "message" => "%{timestamp} %{level} user %{user} %{action} %{result}"
  }
}
```

---

# **7. Mutate Filter (Modify Fields)**

### **7.1 Lowercase Field**

```ruby
mutate { lowercase => ["user"] }
```

### **7.2 Rename Field**

```ruby
mutate { rename => { "client" => "client_ip" } }
```

### **7.3 Remove Fields**

```ruby
mutate { remove_field => ["host", "path"] }
```

### **7.4 Add Custom Field**

```ruby
mutate { add_field => { "env" => "dev" } }
```

---

# **8. JSON Filter (Parse JSON logs)**

When logs are JSON but passed as string.

Example log:

```
{"user":"admin","action":"login"}
```

Filter:

```ruby
json { source => "message" }
```

---

# **9. KV Filter (Parse key=value logs)**

Log:

```
user=admin action=login ip=10.0.0.5
```

Filter:

```ruby
kv {
  source => "message"
  field_split => " "
  value_split => "="
}
```

---

# **10. Date Filter (Set @timestamp)**

```ruby
date {
  match => ["timestamp", "YYYY-MM-dd HH:mm:ss"]
  target => "@timestamp"
}
```

Ensures correct timeline in Kibana.

---

# **11. GeoIP Filter (Enrich IP Info)**

```ruby
geoip {
  source => "ip"
  target => "geo"
}
```

Adds:

* latitude
* longitude
* country
* city

---

# **12. Conditional Logic (Very Important)**

### **12.1 Filter Only JSON Logs**

```ruby
if "json_logs" in [tags] {
  json { source => "message" }
}
```

### **12.2 Drop Debug Logs**

```ruby
if [level] == "DEBUG" {
  drop {}
}
```

### **12.3 Route to Separate Indices**

```ruby
if [status] >= 500 {
  elasticsearch { index => "errors-%{+YYYY.MM.dd}" }
} else {
  elasticsearch { index => "normal-%{+YYYY.MM.dd}" }
}
```

---

# **13. Complete Apache Log Parsing Example**

Log:

```
127.0.0.1 - - [19/Nov/2025:10:00:00 +0530] "GET /index.html HTTP/1.1" 200 512
```

Pipeline:

```ruby
filter {
  grok {
    match => {
      "message" => "%{IP:client} - - \\[%{HTTPDATE:timestamp}\\] \"%{WORD:method} %{URIPATH:uri} HTTP/%{NUMBER:http_version}\" %{NUMBER:status} %{NUMBER:bytes}"
    }
  }
  date {
    match => ["timestamp", "dd/MMM/YYYY:HH:mm:ss Z"]
  }
}
```

---

# **14. Combining Grok + Mutate + Date (Real Production Example)**

```ruby
filter {
  grok {
    match => { "message" => "%{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:level} user=%{WORD:user} action=%{WORD:action} ip=%{IP:ip}" }
  }

  mutate {
    lowercase => ["user", "action"]
    remove_field => ["host", "path"]
  }

  date {
    match => ["timestamp", "YYYY-MM-dd HH:mm:ss"]
  }
}
```

---

# **15. Example: Ingest Logs from Multiple Sources**

### Multiple inputs, single pipeline

```ruby
input {
  beats { port => 5044 }
  file { path => "/var/log/app/*.log" }
}
```

Different filters based on tags:

```ruby
if "apache" in [tags] {
  grok { match => { "message" => "%{COMBINEDAPACHELOG}" } }
}

if "myapp" in [tags] {
  grok { match => { "message" => "%{TIMESTAMP_ISO8601:timestamp} %{WORD:user} %{WORD:action}" } }
}
```

---

# **16. Output Section (Multiple Examples)**

### **16.1 Send to Elasticsearch**

```ruby
elasticsearch {
  hosts => ["http://10.0.18.1:9200"]
  username => "atin.gupta"
  password => "2313634"
  index => "logstash-%{+YYYY.MM.dd}"
}
```

---

### **16.2 Send to File**

```ruby
file {
  path => "/var/log/logstash/output.log"
}
```

---

### **16.3 Stdout (for debugging)**

```ruby
stdout { codec => rubydebug }
```

---

# **17. Full Realistic Pipeline Example (Production Style)**

```ruby
input {
  beats { port => 5044 }
}

filter {
  if "json" in [tags] {
    json { source => "message" }
  }
  else {
    gro

```
