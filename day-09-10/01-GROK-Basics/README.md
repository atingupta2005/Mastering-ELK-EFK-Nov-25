# **Grok Concepts & Basics**

> **Note for docker-elk users:**
> - Logstash configs go in: `logstash/pipeline/` directory (from docker-elk directory)
> - Custom patterns go in: `logstash/config/patterns/` directory

# **1. What is Grok?**

Grok is Logstash’s built‑in pattern-matching system used to **extract structured fields** from unstructured log lines.

Grok is mainly used in:

* Logstash **filter** stage
* Parsing **application logs**
* Parsing **web server logs** (Apache, Nginx)
* Transforming **system logs** into JSON

Grok uses a set of predefined patterns like:

```
%{IP}
%{NUMBER}
%{WORD}
%{DATA}
%{TIMESTAMP_ISO8601}
```

Each Grok pattern contains:

```
%{PATTERN_NAME:field_name}
```

Example:

```
%{IP:client_ip}
```

Extracts an IP and stores it into a field:

```
"client_ip": "192.168.1.10"
```

---

# **2. Why Do We Need Grok?**

Most logs come as plain text:

```
2025-01-01 12:10:22 INFO user=admin login successful
```

Applications need JSON, such as:

```json
{
  "timestamp": "2025-01-01 12:10:22",
  "level": "INFO",
  "user": "admin",
  "event": "login successful"
}
```

Grok converts text logs → structured JSON logs.

---

# **3. Grok Pattern Format**

General structure:

```
%{PATTERN:FIELD_NAME}
```

Example:

```
%{NUMBER:status}
```

Extracts a number and stores as field `status`.

You can also set field type:

```
%{NUMBER:response_time:int}
```

---

# **4. Built‑in Grok Patterns**

Logstash includes **1200+ predefined Grok patterns** located at:

```
/usr/share/logstash/patterns/
```

Most commonly used:

| Pattern                | Description           | Example                    |
| ---------------------- | --------------------- | -------------------------- |
| `%{IP}`                | IPv4/IPv6 address     | 192.168.1.10               |
| `%{WORD}`              | A word (letters only) | INFO                       |
| `%{LOGLEVEL}`          | Log level             | ERROR                      |
| `%{NUMBER}`            | Numeric value         | 404                        |
| `%{DATA}`              | Anything (non-greedy) | text                       |
| `%{GREEDYDATA}`        | Anything until end    | entire line                |
| `%{TIMESTAMP_ISO8601}` | ISO timestamp         | 2025-11-19T10:12:00        |
| `%{HTTPDATE}`          | Apache time format    | 19/Nov/2025:10:00:00 +0530 |
| `%{URI}`               | Request URI           | /index.html                |

---

# **5. Simple Grok Examples (Basic to Intermediate)**

## **Example 1 — Parse log level**

Log:

```
2025-01-01 INFO Started server
```

Pattern:

```
%{TIMESTAMP_ISO8601:timestamp} %{LOGLEVEL:level} %{GREEDYDATA:message}
```

Extracts:

* timestamp
* level
* message

---

## **Example 2 — Extract user & action**

Log:

```
user=admin action=login status=success
```

Grok:

```
user=%{WORD:user} action=%{WORD:action} status=%{WORD:status}
```

---

## **Example 3 — Extract IP and URL**

Log:

```
10.0.0.1 GET /home 200
```

Pattern:

```
%{IP:client_ip} %{WORD:method} %{URIPATHPARAM:url} %{NUMBER:status}
```

---

## **Example 4 — Using `DATA` for unknown-length fields**

Log:

```
message: user logged in successfully
```

Pattern:

```
message: %{DATA:msg}
```

---

# **6. Grok in Logstash (Real Configuration Examples)**

In Logstash pipeline (`logstash/pipeline/*.conf` from docker-elk directory):

```ruby
filter {
  grok {
    match => { "message" => "%{IP:ip} %{WORD:method} %{URIPATH:url} %{NUMBER:status}" }
  }
}
```

Output:

```json
{
  "ip": "10.0.0.1",
  "method": "GET",
  "url": "/home",
  "status": "200"
}
```

---

# **7. Multi‑Pattern Matching**

Sometimes logs differ in format. Grok supports multiple patterns.

```
grok {
  match => {
    "message" => [
      "%{IP:ip} %{WORD:method} %{URIPATH:url}",
      "%{WORD:method} %{URIPATH:url} from %{IP:ip}"
    ]
  }
}
```

Log 1:

```
10.0.0.1 GET /home
```

Log 2:

```
GET /home from 10.0.0.1
```

Both work.

---

# **8. Creating Custom Grok Patterns**

Pattern file location (from docker-elk directory):

```
logstash/config/patterns/my_patterns
```

Example:

```
USERNAME [a-zA-Z0-9._-]+
```

Use it:

```
%{USERNAME:login_user}
```

---

# **9. Advanced Grok Examples**

## **Example — Parse Apache access log (Common Log Format)**

Log:

```
127.0.0.1 - - [19/Nov/2025:10:00:00 +0530] "GET /index.html HTTP/1.1" 200 512
```

Pattern:

```
%{IP:client} - - \[%{HTTPDATE:timestamp}\] "%{WORD:method} %{URIPATH:uri} HTTP/%{NUMBER:http_version}" %{NUMBER:status} %{NUMBER:bytes}
```

---

## **Example — Parse key=value logs**

```
level=INFO user=admin event=start ip=10.0.0.1
```

Pattern:

```
level=%{LOGLEVEL:level} user=%{WORD:user} event=%{WORD:event} ip=%{IP:ip}
```

---

## **Example — Parse JSON-like logs using Grok**

```
type=user action=login result=true extra={more text here}
```

Pattern:

```
 type=%{WORD:type} action=%{WORD:action} result=%{WORD:result} extra=%{GREEDYDATA:extra}
```

---

# **10. Testing Grok Patterns (Very Important Section)**

### **Method 1 — Using Logstash debug output**

In output:

```ruby
stdout { codec => rubydebug }
```

Shows parsed fields on screen.

---

### **Method 2 — Using Grok Debugger (Kibana Dev Tools)**

Navigate:

```
Kibana → Dev Tools → Grok Debugger
```

Paste:

1. Sample log line
2. Grok expression

Click **Simulate**.

---
