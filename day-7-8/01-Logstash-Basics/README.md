# Logstash Basics

## 1. What is Logstash?

Logstash is a **data processing pipeline tool** used for collecting, transforming, and forwarding data. It is part of the Elastic Stack and works seamlessly with **Elasticsearch 9.x**.

Logstash helps you:

* **Ingest** data from many sources (files, beats, syslogs, cloud services)
* **Parse & transform** logs using filters
* **Send** data to outputs like Elasticsearch

It is especially useful when you need to:

* Clean messy logs
* Extract fields from text
* Apply enrichments
* Standardize data before indexing

---

## 2. Logstash Architecture (Input → Filter → Output)

Logstash processes data in a simple pipeline model:

```
┌────────┐    ┌───────────┐    ┌──────────┐
│ Input  │ →  │  Filter   │ →  │  Output  │
└────────┘    └───────────┘    └──────────┘
```

### Input Stage

Where data comes from. Examples:

* File
* Beats
* Kafka
* HTTP

### Filter Stage

Where data is parsed or transformed. Examples:

* grok → extract fields
* mutate → rename/remove fields
* date → convert timestamps

### Output Stage

Where processed data is sent. Examples:

* Elasticsearch
* stdout (for debugging)

---

## 3. Installing Logstash (Basic Setup)

Below are the verified Logstash **9.2.1** downloads:

**RPM (RHEL/CentOS):**

```
https://artifacts.elastic.co/downloads/logstash/logstash-9.2.1-x86_64.rpm
```

**DEB (Ubuntu/Debian):**

```
https://artifacts.elastic.co/downloads/logstash/logstash-9.2.1-amd64.deb
```

**TAR.GZ (Generic Linux):**

```
https://artifacts.elastic.co/downloads/logstash/logstash-9.2.1-linux-x86_64.tar.gz
```

### Install on Ubuntu/Debian

```
wget https://artifacts.elastic.co/downloads/logstash/logstash-9.2.1-amd64.deb
sudo dpkg -i logstash-9.2.1-amd64.deb
```

### Install on RHEL/CentOS

```
wget https://artifacts.elastic.co/downloads/logstash/logstash-9.2.1-x86_64.rpm
sudo rpm -ivh logstash-9.2.1-x86_64.rpm
```

### Start Logstash (package installs)

```
sudo systemctl start logstash
sudo systemctl enable logstash
```

---

## 4. Logstash Configuration File Structure

A Logstash configuration contains **three blocks**:

```
input {
  ...
}

filter {
  ...
}

output {
  ...
}
```

Each block controls a different stage of the pipeline.

### Example Minimal Config

```
input { stdin {} }

filter {
  mutate { add_field => { "source" => "terminal" } }
}

output {
  stdout { codec => rubydebug }
}
```

Run with:

```
/bin/logstash -f sample.conf
```

---

## 5. Common Inputs (file, beats, stdin)

### stdin Input (for learning)

```
input { stdin {} }
```

Use this to test patterns manually.

### file Input

```
input {
  file {
    path => "/var/log/app.log"
    start_position => "beginning"
  }
}
```

> Note: For production, **Filebeat** is recommended instead of the file input.

### beats Input (recommended)

```
input {
  beats {
    port => 5044
  }
}
```

Use when Filebeat ships logs to Logstash.

---

## 6. Common Outputs (Elasticsearch, stdout)

### stdout Output (for debugging)

```
output {
  stdout { codec => rubydebug }
}
```

### Elasticsearch Output (for 9.x)

```
output {
  elasticsearch {
    hosts => ["http://localhost:9200"]
    index => "logs-%{+YYYY.MM.dd}"
  }
}
```

Supports API key authentication:

```
api_key => "YOUR_API_KEY"
```

---

## 7. Common Filters (grok, mutate, date)

Filters transform incoming data into structured and usable fields.

---

### 7.1 Grok Filter

Grok extracts fields from unstructured text. Logstash includes **hundreds of built-in patterns**.

Example:

```
filter {
  grok {
    match => {
      "message" => "%{IP:client_ip} %{WORD:action} %{DATA:details}"
    }
  }
}
```

Breakdown:

* `%{IP:client_ip}` → extracts an IP address into field `client_ip`
* `%{WORD:action}` → extracts a single word like LOGIN/ERROR
* `%{DATA:details}` → captures everything else

### What if the pattern fails?

If a log line does not match the pattern, Logstash adds:

```
"tags": ["_grokparsefailure"]
```

You will see this in:

* Terminal (rubydebug output)
* Kibana Discover → search: `tags:"_grokparsefailure"`

---

### 7.2 Mutate Filter

Mutate modifies or adds fields.

Example:

```
filter {
  mutate {
    rename => { "clientip" => "client_ip" }
    add_field => { "processed" => "yes" }
    remove_field => ["agent"]
  }
}
```

---

### 7.3 Date Filter

Used to convert timestamps from logs into Logstash’s `@timestamp` field.

Example:

```
filter {
  date {
    match => ["timestamp", "dd/MMM/YYYY:HH:mm:ss Z"]
    target => "@timestamp"
  }
}
```

Correct timestamp parsing is essential for time-based Elasticsearch indexing.
