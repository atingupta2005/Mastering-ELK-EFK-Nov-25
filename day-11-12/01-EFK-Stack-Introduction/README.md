# Day 11 – EFK Stack Introduction (Elasticsearch 9.x | CentOS)

---

## 1. What Is EFK (Elasticsearch, Fluentd, Kibana)

The **EFK Stack** is a log management and analysis system made of three main components:

* **Elasticsearch** → Stores and searches data
* **Fluentd** → Collects and forwards logs
* **Kibana** → Visualizes and searches logs

EFK is commonly used to **collect logs from servers and applications**, store them centrally, and analyze them using dashboards.

### Simple Example of EFK Usage

* Application writes logs to a file
* Fluentd reads the log file
* Fluentd sends logs to Elasticsearch
* User searches logs in Kibana

---

### ASCII Diagram – Basic EFK Flow

```
Log Source  →  Fluentd  →  Elasticsearch  →  Kibana
               (Collect)     (Store)          (View)
```

---

## 2. Difference Between Logstash and Fluentd

Both **Logstash** and **Fluentd** are used for **log collection and processing**, but they are different in design and usage.

### 2.1 Logstash (Quick Recap)

* Part of the ELK stack
* Written in Java
* Uses input → filter → output pipeline
* Suitable for heavy data processing

### 2.2 Fluentd

* Core component of the EFK stack
* Written in Ruby (with C extensions)
* Lightweight and fast
* Designed specifically for log collection

---

### 2.3 Simple Comparison Table

| Feature        | Logstash        | Fluentd        |
| -------------- | --------------- | -------------- |
| Primary Use    | Data processing | Log collection |
| Resource Usage | Heavy           | Lightweight    |
| Configuration  | Complex         | Simple         |
| Plugin Count   | Large           | Large          |
| Common Use     | ELK setups      | EFK setups     |

---

## 3. When to Use EFK Over ELK

EFK is usually preferred when:

* You need **lightweight log collection**
* You are using **containers or Kubernetes**
* You want **low memory usage**
* You do not need heavy log transformation

ELK (with Logstash) is preferred when:

* You need **complex parsing and filtering**
* You have **heavy log transformation needs**
* You are working in **traditional VM or server setups**

---

### Simple Decision Example

* Basic log forwarding → Use **EFK**
* Complex log parsing → Use **ELK**

---

## 4. Basic Fluentd Architecture

Fluentd works using a **simple pipeline model**:

* **Input** → Collect logs
* **Filter** → Modify or enrich logs
* **Output** → Send logs to destination

---

### ASCII Diagram – Fluentd Architecture

```
Log Source
    |
    v
+---------+   +---------+   +-----------+
|  Input  | → |  Filter | → |  Output   |
+---------+   +---------+   +-----------+
                          (Elasticsearch)
```

---

### 4.1 Input Stage

* Reads logs from files, sockets, or containers
* Examples: file input, TCP input

### 4.2 Filter Stage

* Used to modify records
* Can add fields, change field names

### 4.3 Output Stage

* Sends logs to Elasticsearch
* Can also send to files or cloud services

---

## 5. Common Fluentd Plugins

Fluentd works using **plugins**. Plugins decide what Fluentd can read, process, and send.

### 5.1 Common Input Plugins

* `in_tail` → Reads log files
* `in_forward` → Receives logs from other Fluentd agents

### 5.2 Common Filter Plugins

* `parser` → Extracts fields from logs
* `record_transformer` → Modifies fields

### 5.3 Common Output Plugins

* `out_elasticsearch` → Sends logs to Elasticsearch
* `out_stdout` → Prints logs to terminal

---

### ASCII Diagram – Plugin Flow

```
Input Plugin → Filter Plugin → Output Plugin
```

---
